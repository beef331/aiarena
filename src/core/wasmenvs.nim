import wasmedge
import std/[os, times, sequtils]
import worlds, tanks

type
  WasmSeq*[T] = object
    data: uint32 # Pointer to data
    len, capacity: uint32
  WasmEnv* = object
    initFunc, updateFunc, allocFunc, deallocFunc: UnmanagedFunctionInst
    module: ModuleContext
    memory: UnmanagedMemoryInst
    ast: AstModuleContext
    tileData: WasmSeq[Tile] # Heap allocated sequencve inside the runtime
    tankData: WasmSeq[Tank] # Heap allocated sequencve inside the runtime
    worldSize: uint32 # pointer to a `(uint32, uint32)`
    executor: ExecutorContext
    path: string
    lastModified: Time
  WasmProcDef* = object
    name*: string
    paramType*, retType*: seq[ValType]
    hostProc*: HostProc[pointer]
  MissingProcError = object of CatchableError


proc wasmProcDef*(name: string, paramType, retType: openarray[ValType], hostProc: HostProc[pointer]): WasmProcDef =
  WasmProcDef(name: name, paramType: paramType.toSeq, retType: retType.toSeq, hostProc: hostProc)

proc loadWasm*(path: string, hostProcs: openarray[WasmProcDef]): WasmEnv {.raises: [MissingProcError].} =
  result.path = path
  try:
    result.lastModified = getLastModificationTime(path)
    var
      config = ConfigureContext.create()
      stats = StatisticsContext.create()
      loader = config.createLoader()
      validator = config.createValidator()
      wasiModule = createWasiModule()
      store = StoreContext.create()
    result.executor = config.createExecutor(stats)
    loader.parseFromFile(result.ast, path)
    validator.validate(result.ast)
    result.executor.registerImport(store, wasiModule)

    var myModule = ModuleContext.create("env")

    for hostProc in hostProcs:
      var
        typ = FunctionType.create(hostProc.paramType, hostProc.retType)
        inst = typ.createInst(hostProc.hostProc)
      mymodule.addFunction(hostProc.name, inst)

    result.executor.registerImport(store, myModule)
    result.executor.instantiate(result.module, store, result.ast)

    result.updateFunc = result.module.findFunction("update")
    result.initFunc = result.module.findFunction("init")
    result.allocFunc = result.module.findFunction("allocMem")
    result.deallocFunc = result.module.findFunction("deallocMem")

    result.memory = result.module.findMemory("memory")

    template checkType(name: untyped, params, res: openarray[ValType]) =
      try:
        result.name.funcType.ensureType(params, res)
      except Exception as e:
        echo "Failed to load '", astToStr(name), "' ", e.msg

    checkType(updateFunc, [valTypei32, valTypef32], [])
    checkType(initFunc, [], [])
    checkType(allocFunc, [valTypei32], [valtypei32])
    checkType(deallocFunc, [valtypei32], [])

    for name, val in result.fieldPairs:
      when val is UnmanagedFunctionInst:
        if val.isNil:
          raise newException(MissingProcError, "Missing procedure named: " & name[0..^5])

  except WasmError as e:
    echo e.msg
  except OsError as e:
    echo e.msg

proc updateTileData*(env: var WasmEnv, tiles: seq[Tile]) =
  if env.tileData.capacity < uint32 max(tiles.len, 64):
    env.tileData.capacity = uint32 max(tiles.len, 64)
    if env.tileData.data != 0: # We already allocated
      env.executor.invoke(env.deallocFunc, wasmValue(env.tileData.data))
    var res: WasmValue
    env.executor.invoke(env.allocFunc, wasmValue cast[int32](max(uint32 tiles.len, 64u32)), res)
  env.memory.setData(tiles)


proc update*(wasmEnv: var WasmEnv, id: int32, dt: float32) =
  if not wasmEnv.updateFunc.isNil:
    wasmEnv.executor.invoke(wasmEnv.updateFunc, args = [wasmValue(id), wasmValue(dt)])
