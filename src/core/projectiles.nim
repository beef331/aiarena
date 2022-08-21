import truss3D, vmath
import truss3D/[instancemodels]
import directions, worlds

const projectileMoveTime = 0.1f

type
  Projectile* = object
    pos: IVec2
    teamId: int32
    dir: Direction
    moveProgress: float32

  ProjectileRenderData* {.packed.} = object
    teamid: int32
    matrix {.align: 16.}: Mat4

  ProjectileRender* = seq[ProjectileRenderData]

proc update*(projectile: var Projectile, world: World, dt: float32) =
  projectile.moveProgress += dt

proc getRenderPos*(projectile: Projectile): Vec3 =
  result = vec3(float32 projectile.pos.x, 1, float32 projectile.pos.y)
  result = lerp(result, result + projectile.dir.asVec, 1 - (projectile.moveProgress / projectileMoveTime))

proc addToRender*(instModel: var InstancedModel[ProjectileRender], projectile: Projectile) =
  instModel.add ProjectileRenderData(teamId: projectile.teamId, matrix: mat4() * translate(projectile.getRenderPos()) * rotateY(projectile.dir.asRot()))



