import vmath
import projectiles, tanks, worlds, wasmenvs
import std/sugar

type
  Controller = enum
    projectile ## Move projectiles here
    player ## Wait for input from player then act


  InputDevice = enum
    Scripted ## AI controlled with WASM
    Keyboard ## Keyboard controlled
    GamePad ## Controller controlled

  GameInput = object ## Idea if we want to allow human players
    case inputDevice: InputDevice
    of Keyboard:
      ## Some table for Input -> Key
    of GamePad:
      ## Gamepad ID + Input -> Button
    of Scripted:
      wasmEnv: WasmEnv

  GameState* = object
    envIndTank: seq[(int, NativeTank)] # int is the index of the wasmEnv
    projectiles: seq[Projectile]
    world: World
    controller: Controller
    activeIndex: int
    wasmEnvs: seq[WasmEnv] # In a world we dont use Wasm we'd put Gamepad here
    gotInput: bool
    tick: int

const NextTickController = [
    projectile: player, # After projectile 'player' goes
    player: projectile # After 'player' projectile' goes
  ] # Array of controller to next controller, array to make complex relations easier

func activeEnvInd*(gameState: var GameState): var int =
  gameState.envIndTank[gamestate.activeIndex][0]

func activeTank*(gameState: var GameState): var NativeTank =
  gameState.envIndTank[gamestate.activeIndex][1]

func activeWasm*(gameState: var GameState): var WasmEnv =
  gameState.wasmEnvs[gamestate.activeEnvInd]


proc getInput*(gameState: var GameState): Input =
  ## Runs the wasm VM and gets input from the 'getInput' procedure
  # TODO: Smartly handle a delay with FD and a thread that kills operation.
  # Also should ensure the move is legal, in the case it's not perhaps run a few times, or just twice
  # If it fails on second run, end the simulation the AI is too dumb.
  let tanks = collect:
    for (_, tank) in gamestate.envIndTank:
      Tank(tank)
  discard gameState.activeWasm.getInput(gameState.activeTank, tanks, gameState.world, gamestate.projectiles)
  nothing # Just for now we return nothing


func nextTick*(gamestate: var GameState) =
  gamestate.gotInput = false
  gamestate.controller = NextTickController[gamestate.controller]
  inc gamestate.tick

func collisionCheck(gameState: var Gamestate) =
  for i in 0..gamestate.projectiles.high:
    let projPos = gameState.projectiles[i].getPos
    if projPos.x notin 0..gamestate.world.size.x or projPos.y notin 0..gameState.world.size.y:
      gameState.projectiles.del(i)
      continue
    for (_, tank) in gamestate.envIndTank.mitems:
      if tank.getPos == gameState.projectiles[i].getPos:
        gameState.projectiles.del(i)
        tank.damage()
        if tank.isDead:
          # TODO: Play explosion particle effect, imagine a big boom
          discard

func update*(gameState: var GameState, dt: float32) =
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
      gameState.activeIndex = gameState.activeIndex mod gameState.envIndTank.len
      gamestate.nextTick()
  of player:
    if not gamestate.gotInput:
      gamestate.activeTank.input gameState.getInput()
      gamestate.gotInput = true
    else:
      if gameState.activeTank.move(dt):
        gamestate.world[gamestate.activeTank.getPos].teamId = gameState.activeTank.teamId
        gamestate.nextTick()


