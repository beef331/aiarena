import vmath
import truss3D/[instancemodels]
import directions

const
  moveTime = 1f # Amount of time to move from A to B
  turnTime= 0.3f # Amount of time to rotate left/right

type
  Input* = enum
    nothing
    turnLeft
    turnRight
    moveForward
    fire

  TankRenderData *{.packed.}= object
    teamId: int32
    model: Mat4
  TankRender* = seq[TankRenderData]

  Tank* {.pure.} = object of RootObj
    pos: Ivec2
    dir: Direction
    teamId*: int32
    health: int32
    presentInput: Input

  NativeTank* = object of Tank
    moveProgress*: float32 # When this is >= 1 we've reached target move to it

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

func move*(tank: var NativeTank, dt: float32): bool =
  ## Moves the tank and returns true when it's fully moved
  tank.moveProgress -= dt
  result = tank.isFinishedMoving()
  if result:
    case tank.presentInput
    of moveForward:
      tank.pos += ivec2(tank.dir.asVec.xz)
      tank.input nothing
    of turnLeft:
      tank.dir.setToPred()
    of turnRight:
      tank.dir.setToNext()
    of nothing, fire:
      tank.input nothing

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
    lerp(rot, rot + Tau / 2, tank.progress)
  of turnRight:
    lerp(rot, rot - Tau / 2, tank.progress)
  else:
    rot

func isDead*(tank: Tank): bool = tank.health <= 0

func damage*(tank: var Tank) = dec tank.health

func render*(instModel: var InstancedModel[TankRender], tank: NativeTank) =
  instModel.ssboData.add TankRenderData(teamId: tank.teamId, model: mat4() * translate(tank.getRenderPos()) * rotateY(tank.getRenderRot()))

