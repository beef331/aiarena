include wasmedge/exporter
import vmath

type FighterData = ref object
  travelToPoint: bool

proc getHeading: float32 {.importc.}
proc getPos: Vec3 {.importc.}
proc setTarget(pos: Vec2) {.importc.}

var fighterData: array[10, (int32, FighterData)]

proc update(id: int32, dt: float32) {.wasmexport.} =
  let id = int id
  if fighterData[id][1].isNil:
    fighterData[id][1] = FighterData()

  let targetPos = vec2(id.float32, 10f)
  if distSq(getPos().xz, targetPos) < 1:
    fighterData[id][1].travelToPoint = false

  if getPos().lengthSq > 15 * 15:
      fighterData[id][1].travelToPoint = true

  if not fighterData[id][1].travelToPoint:
    setTarget(getPos().xz)
  else:
    setTarget(targetPos)
