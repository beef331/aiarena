import truss3D, vmath
import truss3D/[instancemodels, shaders]
import directions, resources
const projectileMoveTime = 0.1f

type
  Projectile* = object
    pos: IVec2
    teamId: int32
    dir: Direction
    moveProgress: float32
    finishTick: int

  ProjectileRenderData* {.packed.} = object
    matrix {.align: 16.}: Mat4
    teamid: int32

  ProjectileRender* = seq[ProjectileRenderData]

proc init*(_: typedesc[Projectile], pos: IVec2, teamId: int, dir: Direction): Projectile =
  Projectile(pos: pos, teamId: teamId, dir: dir, moveProgress: projectileMoveTime) # Why did i even write constructor?!

func getPos*(projectile: Projectile): IVec2 = projectile.pos
func finishedMoving*(projectile: Projectile): bool = projectile.moveProgress <= 0
func moveTick*(projectile: Projectile): int = projectile.finishTick
func nextPos*(projectile: Projectile): IVec2 = projectile.pos + ivec2(projectile.dir.asVec.xz)
func team*(projectile: Projectile): int32 = projectile.teamId

proc move*(projectile: var Projectile, dt: float32, tick: int) =
  ## Moves the projectile and stores tick if finished
  if projectile.finishTick != tick:
    projectile.moveProgress -= dt
    if projectile.finishedMoving:
      projectile.pos += ivec2(projectile.dir.asVec().xz)
      projectile.moveProgress = projectileMoveTime
      projectile.finishTick = tick

proc getRenderPos*(projectile: Projectile): Vec3 =
  result = vec3(float32 projectile.pos.x, 1.5, float32 projectile.pos.y)
  result = lerp(result, result + projectile.dir.asVec, 1 - (projectile.moveProgress / projectileMoveTime))

var
  projectileModel: InstancedModel[ProjectileRender]
  projectileShader: Shader

addResourceProc:
  projectileModel = loadInstancedModel[ProjectileRender]("assets/models/shell.glb")
  projectileShader = loadShader(ShaderPath"assets/shaders/vert.glsl", ShaderPath"assets/shaders/frag.glsl") # Probably dont need seperate frags...?

proc render*(projectiles: seq[Projectile], viewProj: Mat4) =
  projectileModel.ssbodata.setLen(0)
  for proj in projectiles:
    projectileModel.ssbodata.add ProjectileRenderData(teamId: proj.teamId, matrix: mat4() * translate(proj.getRenderPos()) * rotateY(proj.dir.asRot()))
  if projectileModel.ssbodata.len > 0:
    with projectileShader:
      projectileShader.setUniform("VP", viewProj)
      projectileModel.drawCount = projectileModel.ssbodata.len
      projectileModel.reuploadSSBO()
      projectileModel.render(1)

