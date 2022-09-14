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
  Tile {.packed.} = object
    occupied: bool
    kind: TileKind
    teamId: int32

  Tank {.packed, pure, inheritable.} = object
    pos: Ivec2
    dir: Direction
    teamId: int32
    health: int32
    presentInput: Input
    data: UserData

proc getTileSize(): int32 {.wasmexport.} = int32 sizeof(Tile)
proc getTankSize(): int32 {.wasmexport.} = int32 sizeof(Tank)

proc allocMem(size: int32): pointer {.wasmexport.} = system.alloc(size)
proc deallocMem(address: pointer) {.wasmexport.} = system.dealloc(address)

proc getInput(activeTank: Tank, activeTanks: ptr UncheckedArray[Tank], tankCount: int32, tiles: ptr UncheckedArray[Tile], worldSize: ptr (int32, int32)): Input {.wasmexport.} =
  case activeTank.teamId:
  of 1:
    result = moveForward
  else:
    result = turnRight

