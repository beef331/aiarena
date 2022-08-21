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
    teamId: int32
    health: int32
    presentInput: Input

  NativeTank = object of Tank
    moveProgress*: float32 # When this is >= 1 we've reached target move to it

proc input*(tank: var NativeTank, input: Input) =
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

proc isFinishedMoving*(tank: NativeTank): bool =
  case tank.presentInput:
  of turnLeft, turnRight, moveForward:
    tank.moveProgress <= 0
  of fire: # Maybe we want to play an animation...?
    true
  of nothing:
    true

proc update*(tank: var NativeTank, dt: float32) =
  tank.moveProgress -= dt

proc progress(tank: NativeTank): float32 =
 case tank.presentInput
 of turnLeft, turnRight:
   1 - clamp(tank.moveProgress / turnTime, 0, 1)
 of moveForward:
   1 - clamp(tank.moveProgress / moveTime, 0, 1)
 else:
   1

proc getRenderPos(tank: NativeTank): Vec3 =
  let pos = vec3(float32 tank.pos.x, 1, float32 tank.pos.y)
  case tank.presentInput
  of moveForward:
    lerp(pos, pos + tank.dir.asVec, tank.progress)
  else:
    pos

proc getRenderRot(tank: NativeTank): float32 =
  let rot = tank.dir.asRot()
  case tank.presentInput
  of turnLeft:
    lerp(rot, rot + Tau / 2, tank.progress)
  of turnRight:
    lerp(rot, rot - Tau / 2, tank.progress)
  else:
    rot

proc render*(instModel: var InstancedModel[TankRender], tank: NativeTank) =
  instModel.ssboData.add TankRenderData(teamId: tank.teamId, model: mat4() * translate(tank.getRenderPos()) * rotateY(tank.getRenderRot()))

