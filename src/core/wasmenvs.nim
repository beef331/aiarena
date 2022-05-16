import wasmedge
import std/[os, times]

type
  WasmEnv* = object
    initFunc, updateFunc: UnmanagedFunctionInst
    module: ModuleContext
    ast: AstModuleContext
    executor: ExecutorContext
    path: string
    lastModified: Time

proc loadWasm*(path: string, headingProc, posProc, setTargetProc: HostProc): WasmEnv {.raises: [].} =
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
    var
      headingTyp = FunctionType.create([], [valTypef32])
      headingInst = headingTyp.createInst(headingProc)
      posType = FunctionType.create([], [valTypef32, valTypef32, valTypef32])
      posInst = posType.createInst(posProc)
      setPosType = FunctionType.create([valTypef32, valTypef32], [])
      setPosInst = setPosType.createInst(setTargetProc)

    myModule.addFunction("getHeading", headingInst)
    myModule.addFunction("getPos", posInst)
    myModule.addFunction("setTarget", setPosInst)
    result.executor.registerImport(store, myModule)
    result.executor.instantiate(result.module, store, result.ast)

    result.updateFunc = result.module.findFunction("update")
    result.initFunc = result.module.findFunction("init")
  except:
    echo getCurrentExceptionMsg()

proc update*(wasmEnv: var WasmEnv, id: int32, dt: float32) =
  wasmEnv.executor.invoke(wasmEnv.updateFunc, args = [wasmValue(id), wasmValue(dt)])
