import vmath
import projectiles, tanks, worlds, wasmenvs, resources, directions
import std/sugar
import truss3D/[shaders, inputs]

type
  Controller = enum
    projectile ## Move projectiles here
    player ## Wait for input from player then act


  InputDevice = enum
    Scripted ## AI controlled with WA
    Keyboard ## Keyboard controlled
    GamePad ## Controller controlled

  GameInput = object
    case inputDevice: InputDevice
    of Keyboard:
      ## Some table for Input -> Key
    of GamePad:
      ## Gamepad ID + Input -> Button
    of Scripted:
      wasmEnv: AiEnv

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

func activeInputInd*(gameState: GameState): var int =
  gameState.inputIds[gamestate.activeIndex]

func activeTank*(gameState: GameState): var NativeTank =
  gameState.tanks[gamestate.activeIndex]

func activeInput*(gameState: GameState): var GameInput=
  gameState.inputs[gamestate.activeInputInd]

proc addTank(gameState: GameState, tank: sink NativeTank, inputId: int) =
  gamestate.world[tank.getPos].occupied = true
  gamestate.world[tank.getPos].teamId = tank.teamId
  gamestate.tanks.add tank
  gamestate.inputIds.add inputID

proc spawnProjectile(gameState: GameState) =
  let tank = gameState.activeTank
  gamestate.projectiles.add Projectile.init(tank.getPos, tank.teamId, tank.moveDir)

proc init*(_: typedesc[GameState], width, height: int): GameState =
  result = GameState()
  result.world = testWorld(width, height)
  result.inputs.add GameInput(inputDevice: Scripted, wasmEnv: loadWasm("testai.wasm", []))
  result.addTank(NativeTank.init(ivec2(0), east, 1), 0)
  result.addTank(NativeTank.init(ivec2(9, 0), west, 2), 0)
  #result.addTank(NativeTank.init(ivec2(3, 0), west, 2), 0)
  #result.addTank(NativeTank.init(ivec2(4, 0), west, 3), 0)


proc size*(gamestate: GameState): IVec2 = gamestate.world.size

const NextTickController = [
    projectile: player, # After projectile 'player' goes
    player: projectile # After 'player' projectile' goes
  ] # Array of controller to next controller, array to make complex relations easier

func isValidInput(gameState: GameState, input: Input): bool =
  case input
  of moveForward:
    let
      tank = gameState.activeTank
      targetPos = tank.targetPos
    targetPos in gamestate.world and gamestate.world[targetPos].canMoveTo()
  of fire:
    let
      tank = gameState.activeTank
      targetPos = tank.targetPos
    var friendlyTankThere = false
    for otherTank in gamestate.tanks:
      if tank.teamId == otherTank.teamId and otherTank.getPos == targetPos:
        friendlyTankThere = true
    targetPos in gamestate.world and not friendlyTankThere
  of turnLeft, turnRight, nothing:
    true

proc getInput*(gameState: GameState): Input =
  ## Runs the wasm VM and gets input from the 'getInput' procedure
  # TODO: Smartly handle a delay with FD and a thread that kills operation.
  # Also should ensure the move is legal, in the case it's not perhaps run a few times, or just twice
  # If it fails on second run, end the simulation the AI is too dumb.
  let tanks = collect:
    for tank in gamestate.tanks:
      Tank(tank)
  case gamestate.activeInput.inputDevice:
  of Scripted:
    gameState.gotInput = true
    gamestate.activeInput.wasmEnv.getInput(gameState.activeTank, tanks, gameState.world, gamestate.projectiles)
  of GamePad:
    Input.nothing
  of Keyboard:
    if KeyCodeW.isPressed:
      gamestate.gotInput = true
      moveForward
    elif KeyCodeA.isPressed:
      gamestate.gotInput = true
      turnLeft
    elif KeyCodeD.isPressed:
      gamestate.gotInput = true
      turnRight
    elif KeyCodeSpace.isPressed:
      gamestate.gotInput = true
      fire
    else:
      nothing


func collisionCheck(gameState: Gamestate) =
  for i in countDown(gamestate.projectiles.high, 0):
    if i > gamestate.projectiles.high:
      continue
    let thisProj = gamestate.projectiles[i]
    var hitAnother = false
    for j in countDown(i, 0):
      if i != j:
        if thisProj.getPos == gameState.projectiles[j].getPos or
          thisProj.nextPos == gameState.projectiles[j].getPos or
          gameState.projectiles[j].nextPos == thisProj.getPos:
          hitAnother = true
          gameState.projectiles.del(i)
          gamestate.projectiles.del(j)
          break
    if hitAnother:
      continue

    let projPos = gameState.projectiles[i].getPos
    if projPos notin gamestate.world:
      gameState.projectiles.del(i)
      continue
    for tank in gamestate.tanks.mitems:
      if tank.getPos == thisProj.getPos and tank.teamId != thisProj.team:
        gameState.projectiles.del(i)
        tank.damage()
        if tank.isDead:
          # TODO: Play explosion particle effect, imagine a big boom
          discard
        break # Killed the projectile move to next

func nextTick*(gamestate: GameState) =
  gamestate.gotInput = false
  gamestate.controller = NextTickController[gamestate.controller]
  inc gamestate.tick
  gamestate.collisionCheck() # End of turn check collisions

proc update*(gameState: GameState, dt: float32) =
  case gamestate.controller
  of projectile:
    var allFinished = true
    for proj in gamestate.projectiles.mitems:
      proj.move(dt, gamestate.tick)
      if proj.moveTick != gamestate.tick:
        allFinished = false
    if allFinished:
      inc gamestate.activeIndex
      gameState.activeIndex = gameState.activeIndex mod gameState.tanks.len
      gamestate.nextTick()
  of player:
    if not gamestate.gotInput:
      let input = gameState.getInput()
      if gamestate.gotInput and gamestate.isValidInput input:
        case input
        of fire:
          gameState.spawnProjectile
        of nothing, turnLeft, turnRight, moveForward:
          discard
        gamestate.activeTank.input input
      else:
        gamestate.gotInput = false
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
  gamestate.projectiles.render(viewProj)
  gamestate.tanks.render(viewProj)


