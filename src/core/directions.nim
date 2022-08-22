import vmath

# I use this type of system a lot maybe we make this a generic module apart of truss?!

type
  Direction* = enum
    north, east, south, west

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
    0f
  of east:
    Tau * 0.75
  of south:
    Tau / 2
  of west:
    Tau / 4


proc setToNext*(dir: var Direction) =
  if dir == Direction.high:
    dir = Direction.low
  else:
    dir = succ(dir)

proc setToPred*(dir: var Direction) =
  if dir == Direction.low:
    dir = dir.high
  else:
    dir = pred(dir)
