import truss3D, vmath, wasmedge, opengl
import truss3D/[inputs, shaders, models, instancemodels]
import std/[os, times, enumerate]
import core/[resources, gamestates]

shaderPath = "assets/shaders"
modelPath = "assets/models"

addEvent(KeyCodeQ, pressed, epHigh) do(keyEvent: var KeyEvent, dt: float):
  echo "buh bye"
  quitTruss()


var
  view, proj: Mat4
  gameState = GameState.init(10, 10)

proc init() =
  glClearColor(0.5, 0.5, 0.5, 1)
  invokeResourceProcs()

proc update(dt: float32) =
  let
    camPos = vec3(gamestate.size.x / 2, 3, - 3)
    lookPos = vec3(gamestate.size.x / 2, 0, gamestate.size.y / 2)
  view = lookAt(camPos, lookPos, vec3(0, 1, 0))
  proj = perspective(90f, screenSize().x.float / screenSize().y.float, 0.01, 1000)


proc draw() =
  gameState.render(proj * view)



initTruss("Hello", ivec2(1280, 720), init, update, draw)
