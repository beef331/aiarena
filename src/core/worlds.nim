import truss3D, vmath, wasmedge, opengl
import truss3D/[inputs, shaders, models, instancemodels]
import resources

const projectileSpeed = 10f

type
  TileKind* = enum
    empty
    wall
    floor
    controlPoint # For area control game modes, last team changes the colour of the tile

  Tile* {.packed.} = object
    occupied*: bool
    kind*: TileKind
    teamId*: int32

  World* = object
    size*: IVec2
    data*: seq[Tile]

  TileRenderData {.packed.} = object
    pos: Vec3
    teamId: int32

  TileRender = seq[TileRenderData]

  WorldIndexError* = object of CatchableError # Am I really this crazy?!

proc testWorld*(width, height: int): World =
  result = World(size: ivec2(width, height), data: newSeq[Tile](width * height))
  for val in result.data.mitems:
    val.kind = floor

proc contains*(world: World, pos: IVec2): bool = pos.x in 0..<world.size.x and pos.y in 0..<world.size.y


proc `[]`*(world: World, pos: IVec2): Tile =
  if pos in world:
    world.data[pos.x + pos.y * world.size.x]
  else:
    raise newException(WorldIndexError, "Outside range of the world")

proc `[]`*(world: var World, pos: IVec2): var Tile =
  if pos in world:
    result = world.data[pos.x + pos.y * world.size.x]
  else:
    raise newException(WorldIndexError, "Outside range of the world")

const walkable = {TileKind.floor, controlPoint}

proc canMoveTo*(tile: Tile): bool = tile.kind in walkable and not tile.occupied

const modelHeights = [
    empty: 0f,
    wall: 1,
    floor: 0,
    controlPoint: 0
  ]

var
  tileModels: array[TileKind, InstancedModel[TileRender]]
  tileShader: Shader

addResourceProc:
  tileShader = loadShader(ShaderPath"tilevert.glsl", ShaderPath"tilefrag.glsl")
  for tile, _ in tileModels.pairs:
    if tile != empty:
      tileModels[tile] = loadInstancedModel[TileRender]("assets/models/cube.glb")

proc render*(world: World, viewProj: Mat4) =
  for model in tileModels.mitems:
    model.ssboData.setLen(0)
    model.drawCount = 0
  for i, tile in world.data.pairs:
    if tile.kind != empty:
      let
        y = modelHeights[tile.kind]
        pos = vec3(float32(i mod world.size.x), y, float32(i div world.size.x))
      tileModels[tile.kind].ssboData.add TileRenderData(pos: pos, teamId: tile.teamId)
  for model in tileModels.mitems:
    if model.ssboData.len > 0:
      glEnable(GlDepthTest)
      model.reuploadSsbo()
      model.drawCount = model.ssboData.len
      with tileShader:
        tileShader.setUniform("VP", viewProj)
        model.render(1)
