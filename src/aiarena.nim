import truss3D, vmath, wasmedge, opengl
import truss3D/[inputs, shaders, models, instancemodels]
import std/[os, times, enumerate]
import core/[resources, gamestates]

shaderPath = "assets/shaders"
modelPath = "assets/models"

addEvent(KeyCodeQ, pressed, epHigh) do(keyEvent: var KeyEvent, dt: float):
  echo "buh bye"
  quitTruss()


proc init() =
  glClearColor(0.5, 0.5, 0.5, 1)
  invokeResourceProcs()

proc update(dt: float32) =
  ##


proc draw() =
  ##



initTruss("Hello", ivec2(1280, 720), init, update, draw)
