import vmath
import truss3D/[instancemodels]

const
  moveSpeed = 1f # Amount of time to move from A to B
  turnSpeed = 0.3f # Amount of time to rotate left/right

type
  Direction* = enum
    north, east, south, west

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

proc asVec*(dir: Direction): Vec3 =
  case dir
  of north:
    vec3(0, 0, 1)
  of east:
    vec3(1, 0, 0)
  of south:
    vec3(0, 0, -1)
  of west:
    vec3(-1, 0, 0)

proc asRot*(dir: Direction): float32 =
  case dir
  of north:
    Tau / 4
  of east:
    0
  of south:
    Tau * 0.75
  of west:
    Tau / 2

proc input*(tank: var NativeTank, input: Input) =
  tank.presentInput = input
  case input
  of turnLeft .. moveForward:
    tank.moveProgress = 0
  of fire:
    ## Shoot
  of nothing:
    discard

proc isFinishedMoving*(tank: NativeTank): bool =
  case tank.presentInput:
  of turnLeft, turnRight:
    tank.moveProgress >= turnSpeed
  of moveForward:
    tank.moveProgress >= moveSpeed
  of fire: # Maybe we want to play an animation...?
    true
  of nothing:
    true

proc update*(tank: var NativeTank, dt: float32) =
  tank.moveProgress += dt


proc getRenderPos(tank: NativeTank): Vec3 =
  let pos = vec3(float32 tank.pos.x, 1, float32 tank.pos.y)
  case tank.presentInput
  of moveForward:
    lerp(pos, pos + tank.dir.asVec, tank.moveProgress / moveSpeed)
  else:
    pos

proc getRenderRot(tank: NativeTank): float32 =
  let rot = tank.dir.asRot()
  case tank.presentInput
  of turnLeft:
    lerp(rot, rot + Tau / 2, tank.moveProgress / turnSpeed)
  of turnRight:
    lerp(rot, rot - Tau / 2, tank.moveProgress / turnSpeed)
  else:
    rot

proc render*(instModel: var InstancedModel[TankRender], tank: NativeTank) =
  instModel.ssboData.add TankRenderData(teamId: tank.teamId, model: mat4() * translate(tank.getRenderPos()) * rotateY(tank.getRenderRot()))

