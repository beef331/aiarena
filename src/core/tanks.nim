import vmath
import truss3D/[instancemodels, shaders]
import directions, resources

const
  moveTime = 0.2f # Amount of time to move from A to B
  turnTime= 0.3f # Amount of time to rotate left/right

type
  Input* = enum
    nothing
    turnLeft
    turnRight
    moveForward
    fire

  TankRenderData* {.packed.}= object
    model {.align: 16.}: Mat4
    teamId: int32
  TankRender* = seq[TankRenderData]

  Tank* {.pure, inheritable.} = object
    pos: Ivec2
    dir: Direction
    teamId*: int32
    health: int32
    presentInput: Input

  NativeTank* = object of Tank
    moveProgress*: float32 # When this is >= 1 we've reached target move to it

func init*(_: typedesc[NativeTank], pos: IVec2, dir: Direction, teamId: int): NativeTank =
  NativeTank(pos: pos, dir: dir, teamId: teamId)

proc targetPos*(tank: Tank): IVec2 =
  ## Returns where the tank will shoot or move to
  tank.pos + ivec2(tank.dir.asVec.xz)

func input*(tank: var NativeTank, input: Input) =
  tank.presentInput = input
  case input
  of turnLeft, turnRight:
    tank.moveProgress = turnTime
  of moveForward:
    tank.moveProgress = moveTime
  of fire:
    ## Shoot
  of nothing:
    discard

func isFinishedMoving*(tank: NativeTank): bool =
  case tank.presentInput:
  of turnLeft, turnRight, moveForward:
    tank.moveProgress <= 0
  of fire: # Maybe we want to play an animation...?
    true
  of nothing:
    true

func move*(tank: var NativeTank, dt: float32, onFinishedMoving: proc()) =
  ## Moves the tank and returns true when it's fully moved
  tank.moveProgress -= dt
  if tank.isFinishedMoving():
    case tank.presentInput
    of moveForward:
      tank.pos += ivec2(tank.dir.asVec.xz)
    of turnLeft:
      tank.dir.setToNext()
    of turnRight:
      tank.dir.setToPred()
    of nothing, fire:
      discard
    tank.input nothing
    onFinishedMoving()

proc moveDir*(tank: Tank): Direction = tank.dir

proc progress*(tank: NativeTank): float32 =
 case tank.presentInput
 of turnLeft, turnRight:
   1 - clamp(tank.moveProgress / turnTime, 0, 1)
 of moveForward:
   1 - clamp(tank.moveProgress / moveTime, 0, 1)
 else:
   1

func getPos*(tank: Tank): Ivec2 = tank.pos

func fullyMoved*(tank: NativeTank): bool = tank.progress <= 0

func getRenderPos(tank: NativeTank): Vec3 =
  let pos = vec3(float32 tank.pos.x, 1, float32 tank.pos.y)
  case tank.presentInput
  of moveForward:
    lerp(pos, pos + tank.dir.asVec, tank.progress)
  else:
    pos

func getRenderRot(tank: NativeTank): float32 =
  let rot = tank.dir.asRot()
  case tank.presentInput
  of turnLeft:
    if tank.fullyMoved:
      rot
    else:
      lerp(rot, rot - Tau / 4, tank.progress)
  of turnRight:
    if tank.fullyMoved:
      rot
    else:
      lerp(rot, rot + Tau / 4, tank.progress)
  else:
    rot

func isDead*(tank: Tank): bool = tank.health <= 0

func damage*(tank: var Tank) = dec tank.health

var
  tankModel: InstancedModel[TankRender]
  tankShader: Shader

addResourceProc:
  tankModel = loadInstancedModel[TankRender]("assets/models/tank.obj")
  tankShader = loadShader(ShaderPath"assets/shaders/vert.glsl", ShaderPath"assets/shaders/frag.glsl")

proc render*(tanks: seq[NativeTank], viewProj: Mat4) =
  # Set shader
  with tankShader:
    tankShader.setUniform("VP", viewProj)
    tankModel.ssboData.setLen(0)
    for tank in tanks:
      tankModel.ssboData.add TankRenderData(teamId: tank.teamId, model: mat4() * translate(tank.getRenderPos()) * rotateY(tank.getRenderRot()))
    tankModel.drawCount = tankModel.ssboData.len
    tankModel.reuploadSsbo()
    tankModel.render(1)

