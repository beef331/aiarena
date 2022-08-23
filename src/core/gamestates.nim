import vmath
import projectiles, tanks, worlds, wasmenvs, resources, directions
import std/sugar
import truss3D/[shaders]

type
  Controller = enum
    projectile ## Move projectiles here
    player ## Wait for input from player then act


  InputDevice = enum
    Scripted ## AI controlled with WASM
    Keyboard ## Keyboard controlled
    GamePad ## Controller controlled

  GameInput = object
    case inputDevice: InputDevice
    of Keyboard:
      ## Some table for Input -> Key
    of GamePad:
      ## Gamepad ID + Input -> Button
    of Scripted:
      wasmEnv: WasmEnv

  GameState* = ref object
    tanks: seq[NativeTank] # int is the index of the wasmEnv
    inputIds: seq[int]
    projectiles: seq[Projectile]
    world: World
    controller: Controller
    activeIndex: int
    inputs: seq[GameInput]
    gotInput: bool
    tick: int


proc addTank(gameState: var GameState, tank: sink NativeTank, inputId: int) =
  gamestate.world[tank.getPos].occupied = true
  gamestate.tanks.add tank
  gamestate.inputIds.add inputID
  gamestate.inputs.add default(GameInput) # Remove this later


proc init*(_: typedesc[GameState], width, height: int): GameState =
  result = GameState()
  result.world = testWorld(width, height)
  result.addTank(NativeTank.init(ivec2(0), north, 0), 0)
  result.addTank(NativeTank.init(ivec2(9, 9), south, 0), 0)
  result.addTank(NativeTank.init(ivec2(0, 9), east, 0), 0)
  result.addTank(NativeTank.init(ivec2(9, 0), west, 0), 0)


proc size*(gamestate: GameState): IVec2 = gamestate.world.size

const NextTickController = [
    projectile: player, # After projectile 'player' goes
    player: projectile # After 'player' projectile' goes
  ] # Array of controller to next controller, array to make complex relations easier

func activeInputInd*(gameState: GameState): var int =
  gameState.inputIds[gamestate.activeIndex]

func activeTank*(gameState: GameState): var NativeTank =
  gameState.tanks[gamestate.activeIndex]

func activeInput*(gameState: GameState): var GameInput=
  gameState.inputs[gamestate.activeInputInd]


func isValidInput(gameState: GameState, input: Input): bool =
  case input
  of moveForward:
    let
      tank = gameState.activeTank
      targetPos = tank.getPos + ivec2(tank.moveDir.asVec.xz)
    targetPos in gamestate.world and not gamestate.world[targetPos].occupied
  of fire:
    true # TODO: Handlethis
  of turnLeft, turnRight, nothing:
    true

func getInput*(gameState: GameState): Input =
  ## Runs the wasm VM and gets input from the 'getInput' procedure
  # TODO: Smartly handle a delay with FD and a thread that kills operation.
  # Also should ensure the move is legal, in the case it's not perhaps run a few times, or just twice
  # If it fails on second run, end the simulation the AI is too dumb.
  let tanks = collect:
    for tank in gamestate.tanks:
      Tank(tank)
  case gamestate.activeInput.inputDevice:
  of Scripted:
    ##discard gamestate.activeInput.wasmEnv.getInput(gameState.activeTank, tanks, gameState.world, gamestate.projectiles)
  of GamePad:
    discard
  of Keyboard:
    discard
  if gameState.isValidInput(moveForward):
    moveForward
  else:
    turnLeft


func nextTick*(gamestate: GameState) =
  gamestate.gotInput = false
  gamestate.controller = NextTickController[gamestate.controller]
  inc gamestate.tick

func collisionCheck(gameState: Gamestate) =
  for i in 0..gamestate.projectiles.high:
    let projPos = gameState.projectiles[i].getPos
    if projPos.x notin 0..gamestate.world.size.x or projPos.y notin 0..gameState.world.size.y:
      gameState.projectiles.del(i)
      continue
    for tank in gamestate.tanks.mitems:
      if tank.getPos == gameState.projectiles[i].getPos:
        gameState.projectiles.del(i)
        tank.damage()
        if tank.isDead:
          # TODO: Play explosion particle effect, imagine a big boom
          discard

func update*(gameState: GameState, dt: float32) =
  case gamestate.controller
  of projectile:
    var allFinished = true
    for proj in gamestate.projectiles.mitems:
      proj.move(dt, gamestate.tick)
      if proj.moveTick != gamestate.tick:
        allFinished = false
    if allFinished:
      gamestate.collisionCheck()
      inc gamestate.activeIndex
      gameState.activeIndex = gameState.activeIndex mod gameState.tanks.len
      gamestate.nextTick()
  of player:
    if not gamestate.gotInput:
      gamestate.activeTank.input gameState.getInput()
      gamestate.gotInput = true
    else:
      let startPos = gamestate.activeTank.getPos()
      gameState.activeTank.move(dt, proc() =
        gamestate.world[startPos].occupied = false
        let pos = gamestate.activeTank.getPos
        gamestate.world[pos].occupied = true
        gamestate.world[pos].teamId = gameState.activeTank.teamId
        gamestate.nextTick()
      )

var colorSsbo: Ssbo[array[4, Vec4]]

addResourceProc:
  let teamColours = [
      vec4(1, 1, 1, 1),
      vec4(1, 0, 0, 1),
      vec4(0, 1, 0, 1),
      vec4(0, 0, 1, 1)
    ]
  colorSsbo = genSsbo[typeof(teamColours)](2)
  teamColours.copyTo(colorSsbo)

proc render*(gameState: GameState, viewProj: Mat4) =
  colorSsbo.bindBuffer()
  gamestate.world.render(viewProj)
  gamestate.tanks.render(viewProj)


