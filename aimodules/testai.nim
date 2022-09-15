import wasm3/exporter
import vmath
import ../src/core/directions


type
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
    target: int
  Tile {.packed.} = object
    occupied: bool
    kind: TileKind
    teamId: int32

  Tank {.packed.} = object
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

proc isOccupied(pos, size: Ivec2, tiles: ptr UncheckedArray[Tile]): bool =
  if pos.x in 0..<size.x and pos.y in 0..<size.y:
    tiles[pos.x + pos.y * size.x].occupied
  else:
    true

proc getInput(activeTank: ptr Tank, activeTanks: ptr UncheckedArray[Tank], tankCount: int32, tiles: ptr UncheckedArray[Tile], worldSize: ptr IVec2): Input {.wasmexport.} =
  let
    forwardPos = activeTank.pos + ivec2(activeTank.dir.asVec.xz)
    rightPos = activeTank.pos + ivec2(activeTank.dir.nextVal.asVec.xz)
    leftPos = activeTank.pos + ivec2(activeTank.dir.prevVal.asVec.xz)
    isForwardOccupied = forwardPos.isOccupied(worldSize[], tiles)
    isRightOccupied = rightPos.isOccupied(worldSize[], tiles)
    isLeftOccupied = leftPos.isOccupied(worldSize[], tiles)
  if activeTank.data == nil:
    activeTank.data = UserData()
    let target = block:
      var a = -1
      for i, x in activeTanks.toOpenArray(0, tankCount - 1):
        if x.pos != activeTank.pos:
          a = i
          break
      a
    activeTank.data.target = target

  if not isForwardOccupied:
    turnRight
  elif not isRightOccupied:
    turnRight
  elif not isLeftOccupied:
    turnRight
  else:
    fire







