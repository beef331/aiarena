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
    Tau / 4
  of east:
    0
  of south:
    Tau * 0.75
  of west:
    Tau / 2
