import projectiles, tanks, worlds, wasmenvs

type
  Controller = enum
    projectile ## Move projectiles here
    player ## Wait for input from player then act

  GameState* = object
    envIndTank: seq[(int, NativeTank)] # int is the index of the wasmEnv
    projectiles: seq[Projectile]
    world: World
    controller: Controller
    activeIndex: int
    wasmEnvs: seq[WasmEnv]
    gotInput: bool
    tick: int

const NextTickController = [
  projectile: player,
  player: projectile
  ]

func activeEnvInd*(gameState: var GameState): var int =
  gameState.envIndTank[gamestate.activeIndex][0]

func activeTank*(gameState: var GameState): var NativeTank =
  gameState.envIndTank[gamestate.activeIndex][1]

func activeWasm*(gameState: var GameState): var WasmEnv =
  gameState.wasmEnvs[gamestate.activeEnvInd]


proc getInput*(gameState: var GameState): Input =
  ## Runs the wasm VM and gets input from the 'getInput' procedure
  #TODO: Smartly handle a delay with FD and a thread that kills operation.
  nothing # Just for now we return nothing


func nextTick*(gamestate: var GameState) =
  gamestate.gotInput = false
  gamestate.controller = NextTickController[gamestate.controller]
  inc gamestate.tick

func update*(gameState: var GameState, dt: float32) =
  case gamestate.controller
  of projectile:
    var allFinished = true
    for proj in gamestate.projectiles.mitems:
      proj.move(dt, gamestate.tick)
      if proj.moveTick != gamestate.tick:
        allFinished = false
    if allFinished:
      gamestate.nextTick()
  of player:
    if not gamestate.gotInput:
      gamestate.activeTank.input gameState.getInput()
    else:
      if gameState.activeTank.move(dt):
        gamestate.nextTick()


