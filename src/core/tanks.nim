import vmath

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

