import wasmedge
import std/[os, times, sequtils]

type
  WasmEnv* = object
    initFunc, updateFunc: UnmanagedFunctionInst
    module: ModuleContext
    ast: AstModuleContext
    executor: ExecutorContext
    path: string
    lastModified: Time
  WasmProcDef* = object
    name*: string
    paramType*, retType*: seq[ValType]
    hostProc*: HostProc[pointer]

proc wasmProcDef*(name: string, paramType, retType: openarray[ValType], hostProc: HostProc[pointer]): WasmProcDef =
  WasmProcDef(name: name, paramType: paramType.toSeq, retType: retType.toSeq, hostProc: hostProc)

proc loadWasm*(path: string, hostProcs: openarray[WasmProcDef]): WasmEnv {.raises: [].} =
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
      echo hostProc.name, " ", hostProc.paramType, " ", hostProc.retType
      mymodule.addFunction(hostProc.name, inst)

    result.executor.registerImport(store, myModule)
    result.executor.instantiate(result.module, store, result.ast)

    result.updateFunc = result.module.findFunction("update")
    result.initFunc = result.module.findFunction("init")
  except WasmError as e:
    echo e.msg
  except OsError as e:
    echo e.msg

proc update*(wasmEnv: var WasmEnv, id: int32, dt: float32) =
  if cast[int](wasmEnv.updateFunc) != 0:
    wasmEnv.executor.invoke(wasmEnv.updateFunc, args = [wasmValue(id), wasmValue(dt)])
