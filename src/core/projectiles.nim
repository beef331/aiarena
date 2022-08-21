import truss3D, vmath
import truss3D/[instancemodels]
import directions

const projectileMoveTime = 0.1f

type
  Projectile* = object
    pos: IVec2
    teamId: int32
    dir: Direction
    moveProgress: float32
    finishTick: int

  ProjectileRenderData* {.packed.} = object
    teamid: int32
    matrix {.align: 16.}: Mat4

  ProjectileRender* = seq[ProjectileRenderData]

func finishedMoving*(projectile: Projectile): bool = projectile.moveProgress <= 0
func moveTick*(projectile: Projectile): int = projectile.finishTick

proc move*(projectile: var Projectile, dt: float32, tick: int) =
  ## Moves the projectile and stores tick if finished
  if projectile.finishTick != tick:
    projectile.moveProgress -= dt
    if projectile.finishedMoving:
      projectile.pos += ivec2(projectile.dir.asVec().xz)
      projectile.moveProgress = projectileMoveTime
      projectile.finishTick = tick

proc getRenderPos*(projectile: Projectile): Vec3 =
  result = vec3(float32 projectile.pos.x, 1, float32 projectile.pos.y)
  result = lerp(result, result + projectile.dir.asVec, 1 - (projectile.moveProgress / projectileMoveTime))

proc addToRender*(instModel: var InstancedModel[ProjectileRender], projectile: Projectile) =
  instModel.ssbodata.add ProjectileRenderData(teamId: projectile.teamId, matrix: mat4() * translate(projectile.getRenderPos()) * rotateY(projectile.dir.asRot()))



