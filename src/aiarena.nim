import truss3D, vmath, wasmedge, opengl
import truss3D/[inputs, shaders, models, instancemodels]
import std/[os, times, enumerate]
import core/[resources, fighters, wasmenvs]

shaderPath = "assets/shaders"
modelPath = "assets/models"

type
  ShipRenderData {.packed.}= object
    pos: Vec3
    teamId: int32
    model: Mat4
  ShipRender = seq[ShipRenderData]

var
  shipModel: InstancedModel[ShipRender]
  targetModel: InstancedModel[ShipRender]
  shipShader: Shader
  teamColors: SSBO[seq[Vec4]]

addResourceProc do:
  shipModel = loadInstancedModel[ShipRender]("ship.glb")
  targetModel = loadInstancedModel[ShipRender]("target.glb")
  shipShader = loadShader(ShaderPath"vert.glsl", ShaderPath"frag.glsl")
  teamColors = genSsbo[seq[Vec4]](2)
  @[vec4(1, 1, 1, 1), vec4(1, 0, 0, 0), vec4(0, 1, 0, 1), vec4(0, 0, 1, 1)].copyTo(teamColors)


type
  Projectile = object
    id: int
    pos: Vec3
  GameData = object
    activeFighter: int
    fighters: seq[Fighter]
    projectiles: seq[Projectile]
    arenaSize: float32
    wasmEnvs: seq[WasmEnv]

addEvent(KeyCodeQ, pressed, epHigh) do(keyEvent: var KeyEvent, dt: float):
  echo "buh bye"
  quitTruss()

var
  gameData = GameData(activeFighter: -1, fighters: @[randFighter(0), randFighter(0), randFighter(0), randFighter(1), randFighter(1), randFighter(1), randFighter(2), randFighter(3)], arenaSize: 20)
  view = lookAt(vec3(0, 3, 0), vec3(0, 0, 0), vec3(0, 1, 0))
  proj = perspective(90f, screenSize().x.float / screenSize().y.float, 0.01, 1000)

proc activeFighter(): var Fighter =
  gameData.fighters[gameData.activeFighter]

proc wasmGetHeading(data: pointer, mem: MemoryInst, params, returns: WasmParamList): WasmResult {.cdecl.} =
  ## Host function for wasm logic
  let fighter = activeFighter()
  returns[0] = wasmValue(fighter.heading + Tau / 4)
  WasmResult()

proc wasmGetPos(data: pointer, mem: MemoryInst, params, returns: WasmParamList): WasmResult {.cdecl.} =
  ## Host function for wasm logic
  let
    fighter = activeFighter()
    pos = fighter.getPos()
  returns[0] = wasmValue(pos.x)
  returns[1] = wasmValue(0f)
  returns[2] = wasmValue(pos.z)
  WasmResult()

proc wasmSetTarget(data: pointer, mem: MemoryInst, params, returns: WasmParamList): WasmResult {.cdecl.} =
  ## Host function for wasm logic
  activeFighter().target = vec3(params[0].getValue[: float32](), 0,  params[1].getValue[: float32]())
  WasmResult()

proc init() =
  glClearColor(0.5, 0.5, 0.5, 1)
  invokeResourceProcs()
  gameData.wasmEnvs.add loadWasm("flytocenter.wasm", wasmGetHeading, wasmGetPos, wasmSetTarget)

proc update(dt: float32) =

  view = lookAt(vec3(0, -20, 0), vec3(0), vec3(0, 0, 1))
  proj = perspective(90f, screenSize().x.float / screenSize().y.float, 0.01, 1000)

  for id, fighter in enumerate gameData.fighters.mitems:
    gameData.activeFighter = id
    gameData.wasmEnvs[0].update(id, dt)
    fighter.update(dt)

  if KeyCodef11.isDown():
    gameData.wasmEnvs[0] = loadWasm("flytocenter.wasm", wasmGetHeading, wasmGetPos, wasmSetTarget)


  shipModel.ssboData.setLen(0)
  targetModel.ssboData.setLen(0)
  for i, fighter in gameData.fighters.pairs:
      shipmodel.ssboData.add ShipRenderData(pos: fighter.getPos(), teamId: fighter.teamId, model: rotateY(fighter.heading))
      targetModel.ssboData.add ShipRenderData(pos: fighter.getTarget(), teamId: fighter.teamId, model: mat4())
  shipModel.drawCount = shipmodel.ssboData.len
  targetModel.drawCount = targetModel.ssboData.len
  targetModel.reuploadSsbo()
  shipModel.reuploadSsbo()



proc draw() =
  with shipShader:
    glEnable(GlDepthTest)
    shipShader.setUniform("VP", proj * view)
    shipModel.render(1)
    targetModel.render(1)


initTruss("Hello", ivec2(1280, 720), init, update, draw)
