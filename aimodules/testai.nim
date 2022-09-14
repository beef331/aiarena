import wasm3/exporter
import vmath

type
  Direction = enum
    north, east, south, west
  TileKind = enum
    empty
    wall
    floor
    controlPoint # For area control game modes, last team changes the colour of the tile
  Input = enum
    nothing
    turnLeft
    turnRight
    moveForward
    fire
  UserData = ref object
  Tile = object
    occupied: bool
    kind: TileKind
    teamId: int
  Tank {.packed, pure, inheritable.} = object
    pos: Ivec2
    dir: Direction
    teamId: int32
    health: int32
    presentInput: Input
    data: UserData

exportVar(worldSize, (int32, int32))
exportVar(tankCount, int32)

proc allocMem(size: int32): pointer {.wasmexport.} = system.alloc(size)
proc deallocMem(address: pointer) {.wasmexport.} = system.dealloc(address)

proc getInput(activeTank: Tank, activeTanks: ptr UncheckedArray[Tank], tiles: ptr UncheckedArray[Tile]): Input {.wasmexport.} =
  echo worldSize
  case activeTank.teamId:
  of 1:
    result = moveForward
  else:
    result = turnRight

