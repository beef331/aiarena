import truss3D, vmath, wasmedge, opengl
import truss3D/[inputs, shaders, models, instancemodels]

const projectileSpeed = 10f

type
  TileKind* = enum
    empty
    wall
    floor
    controlPoint # For area control game modes, last team changes the colour of the tile

  Tile* = object
    occupied*: bool
    kind*: TileKind
    teamId*: int

  World* = object
    size*: IVec2
    data*: seq[Tile]

  TileRenderData {.packed.}= object
    pos: Vec3
    teamId: int32

  TileRender = seq[TileRenderData]

  WorldIndexError* = object of CatchableError

proc `[]`*(world: World, pos: IVec2): Tile =
  if pos.x in 0..world.size.x and pos.y in 0..world.size.y:
    world.data[pos.x + pos.y * world.size.x]
  else:
    raise newException(WorldIndexError, "Outside range of the world")

proc `[]`*(world: var World, pos: IVec2): var Tile =
  if pos.x in 0..world.size.x and pos.y in 0..world.size.y:
    result = world.data[pos.x + pos.y * world.size.x]
  else:
    raise newException(WorldIndexError, "Outside range of the world")

const walkable = {floor, controlPoint}

proc canMoveTo*(tile: Tile): bool = tile.kind in walkable and not tile.occupied

const modelHeights = [
  empty: 0f,
  wall: 1,
  floor: 0,
  controlPoint: 0
  ]

var tileModels: array[TileKind, InstancedModel[TileRender]]

proc render*(world: World) =
  for model in tileModels.mitems:
    model.ssboData.setLen(0)
    model.drawCount = 0
  for i, tile in world.data.pairs:
    if tile.kind != empty:
      let
        y = modelHeights[tile.kind]
        pos = vec3(float32(i / world.size.x), y, float32(i mod world.size.x))
      tileModels[tile.kind].ssboData.add TileRenderData(pos: pos, teamId: tile.teamId)
  for model in tileModels.mitems:
    if model.ssboData.len > 0:
      model.drawCount = model.ssboData.len
      ## Render models
