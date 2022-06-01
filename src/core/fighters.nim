import vmath
import std/math
const
  maxSpeed = 5f
  turnSpeed = 2f
  timeBetweenShot = 0.3f
type Fighter* = object
  pos: Vec3
  velocity: Vec3
  heading*: float32
  target*: Vec3
  team: int32
  lastShotTime: float32


import std/random
proc randFighter*(teamId: int32): Fighter = Fighter(pos: vec3(rand(-15f..15f), 0, rand(-15f..15f)), heading: -Tau / 4, team: teamId)

proc teamId*(fighter: Fighter): int32 = fighter.team

proc update*(fighter: var Fighter, dt: float32) =
  fighter.pos += fighter.velocity * dt
  fighter.velocity += rotateY(fighter.heading) * vec3(0, 0, 1)
  fighter.velocity = clamp(fighter.velocity.length / maxSpeed, 0f..1f) * maxSpeed * fighter.velocity.normalize()
  fighter.target.y = 0
  fighter.pos.y = 0
  if distSq(fighter.target, fighter.pos) > 2: # If the target is on us we just fly straight
    let
      tempDir = dir(fighter.heading + Tau / 4)
      currentDir = vec3(tempDir.x, 0, tempDir.y).normalize()
      targetDir = (fighter.target - fighter.pos).normalize()
      crossProd = cross(currentDir, targetDir)
    if dot(crossProd, vec3(0, 1, 0)) > 0:
      fighter.heading -= dt * turnSpeed
    else:
      fighter.heading += dt * turnSpeed
  fighter.lastShotTime -= dt

proc getPos*(fighter: Fighter): Vec3 = fighter.pos

proc getTarget*(fighter: Fighter): Vec3 = fighter.target

proc canFire*(fighter: Fighter): bool = fighter.lastShotTime <= 0

proc fire*(fighter: var Fighter) =
  fighter.lastShotTime = timeBetweenShot
