import wasm3, vmath
import wasm3/wasm3c
import std/[os, times, sequtils]
import worlds, tanks, projectiles

type
  WasmSeq*[T] = object
    data: uint32 # Pointer to data
    len, capacity: uint32
  AiEnv* = object
    inputFunc, allocFunc, deallocFunc: PFunction
    tileData: WasmSeq[Tile] # Heap allocated sequencve inside the runtime
    tankData: WasmSeq[Tank] # Heap allocated sequencve inside the runtime
    worldSize: uint32 # pointer to a `(uint32, uint32)`
    activeTank: uint32 # pointer to a tank
    tankCount: PGlobal
    path: string # Path to watch
    lastModified: Time
    wasmEnv: WasmEnv
  MissingProcError = object of CatchableError


proc loadWasm*(path: string, hostProcs: openarray[WasmHostProc]): AiEnv =
  result.path = path
  try:
    result.lastModified = getLastModificationTime(path)
    result.wasmEnv = loadWasmEnv(readFile(path), hostProcs = hostProcs)
    result.allocFunc = result.wasmEnv.findFunction("allocMem", [I32], [I32])
    result.deallocFunc = result.wasmEnv.findFunction("deallocMem", [I32], [])
    result.inputFunc = result.wasmEnv.findFunction("getInput", [I32, I32, I32], [I32])
    result.activeTank = cast[uint32](result.allocFunc.call(int32, sizeof(Tank)))
    result.tankCount = result.wasmEnv.findGlobal("tankCount")
    var
      worldSize = result.wasmEnv.findGlobal("worldSize")
      newWorldSize = Wasmval(kind: I32)
    result.worldSize = cast[uint32](result.allocFunc.call(int32, int32 sizeof((int32, int32))))
    newWorldSize.i32 = cast[int32](result.worldSize)
    echo worldSize.m3SetGlobal(addr newWorldSize)


  except OsError as e:
    echo e.msg

proc updateData*(env: var AiEnv, tiles: seq[Tile]) =
  if env.tileData.capacity < uint32(tiles.len * sizeof(Tile)):
    env.deallocFunc.call(void, cast[int32](env.tileData.data))
    env.tileData.data = cast[uint32](env.allocFunc.call(int32, cast[int32](tiles.len * sizeof(Tile))))
  env.tileData.len = uint32 tiles.len
  env.wasmEnv.copyMem(env.tileData.data, tiles[0].unsafeAddr, tiles.len * sizeof(Tile))

proc updateData*(env: var AiEnv, tanks: seq[Tank]) =
  if env.tankData.capacity < uint32(tanks.len * sizeof(Tank)):
    env.deallocFunc.call(void, cast[int32](env.tankData.data))
    env.tankData.data = cast[uint32](env.allocFunc.call(int32, cast[int32](tanks.len * sizeof(Tank))))
  env.tankData.len = uint32 tanks.len
  env.wasmEnv.copyMem(env.tankData.data, tanks[0].unsafeAddr, tanks.len * sizeof(Tank))

proc getInput*(env: var AiEnv, activeTank: Tank, tanks: seq[Tank], world: World, projectile: seq[Projectile]): Input =
  env.wasmEnv.setMem(activeTank, env.activeTank)
  env.updateData(tanks)
  env.updateData(world.data)
  env.wasmEnv.setMem((world.size.x, world.size.y), env.worldSize)
  result = Input(env.inputFunc.call(int32, env.activeTank, 0i32, 0i32))
  echo result
