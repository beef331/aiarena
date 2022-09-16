import wasm3/exporter
import vmath
import ../src/core/directions
import std/options


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
    id: int32
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

proc findClosestEnemy(tank: Tank, activeTanks: openArray[Tank]): Option[Tank] =
  var closest = float32.high
  for otherTank in activeTanks:
    if otherTank.teamId != tank.teamId:
      let dist = otherTank.pos.vec2.distSq(tank.pos.vec2)
      if closest > dist:
        closest = dist
        result = some(otherTank)

proc getInput(dir: Direction, target: IVec2): Input =
  if target.y == 0:
    case dir
    of north:
      if target.x < 0:
        turnLeft
      else:
        turnRight
    of east:
      if target.x < 0:
        turnLeft
      else:
        fire
    of south:
      if target.x < 0:
        turnRight
      else:
        turnLeft
    of west:
      if target.x < 0:
        fire
      else:
        turnRight
  elif target.x == 0:
    case dir
    of north:
      if target.y < 0:
        turnLeft
      else:
        fire
    of east:
      if target.y < 0:
        turnRight
      else:
        turnLeft
    of south:
      if target.y < 0:
        fire
      else:
        turnLeft
    of west:
      if target.y < 0:
        fire
      else:
        turnRight
  else:
    moveForward

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

  let closestEnemy = activeTank[].findClosestEnemy(activeTanks.toOpenArray(0, tankCount - 1))
  if closestEnemy.isSome:
    let
      targetPos = closestEnemy.get.pos
      delta = targetPos - activeTank.pos
    result = activeTank.dir.getInput(delta)


    #if abs(delta.x) < abs(delta.y): # This is dumb we need pathfinding, for flat square map this works









