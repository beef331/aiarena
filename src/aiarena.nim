import truss3D, vmath, wasmedge, opengl
import truss3D/[inputs, shaders, models, instancemodels]
import std/[os, times, enumerate]
import core/[resources, tanks, wasmenvs, worlds, projectiles]

shaderPath = "assets/shaders"
modelPath = "assets/models"

const projectileSpeed = 10f

type
  GameData = object
    tanks: seq[Tank]
    arenaSize: float32
    wasmEnvs: seq[WasmEnv]

var
  tankModel: InstancedModel[TankRender]
  tankShader, projectileShader: Shader
  teamColors: SSBO[seq[Vec4]]

addResourceProc do:
  tankModel = loadInstancedModel[TankRender]("ship.glb")
  tankShader = loadShader(ShaderPath"vert.glsl", ShaderPath"frag.glsl")
  projectileShader = loadShader(ShaderPath"projvert.glsl", ShaderPath"projfrag.glsl")
  teamColors = genSsbo[seq[Vec4]](2)
  @[vec4(1, 1, 1, 1), vec4(1, 0, 0, 0), vec4(0, 1, 0, 1), vec4(0, 0, 1, 1)].copyTo(teamColors)




addEvent(KeyCodeQ, pressed, epHigh) do(keyEvent: var KeyEvent, dt: float):
  echo "buh bye"
  quitTruss()

var
  gameData = GameData()
  view = lookAt(vec3(0, 3, 0), vec3(0, 0, 0), vec3(0, 1, 0))
  proj = perspective(90f, screenSize().x.float / screenSize().y.float, 0.01, 1000)

const wasmProcs = array[0, WasmProcDef]([])


proc init() =
  glClearColor(0.5, 0.5, 0.5, 1)
  invokeResourceProcs()
  gameData.wasmEnvs.add loadWasm("flytocenter.wasm", wasmProcs)

proc update(dt: float32) =

  view = lookAt(vec3(0, -20, 0), vec3(0), vec3(0, 0, 1))
  proj = perspective(90f, screenSize().x.float / screenSize().y.float, 0.01, 1000)

  if KeyCodef11.isDown():
    gameData.wasmEnvs[0] = loadWasm("flytocenter.wasm", wasmProcs)


proc draw() =
  teamColors.bindBuffer()
  with projectileShader:
    projectileShader.setUniform("VP", proj * view)
  with tankShader:
    glEnable(GlDepthTest)
    tankShader.setUniform("VP", proj * view)
    tankModel.render(1)




initTruss("Hello", ivec2(1280, 720), init, update, draw)
