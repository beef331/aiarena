#version 430
layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 uv;
uniform mat4 VP;

struct data{
  mat4 model;
  int team;
};

layout(std430, binding = 1) buffer instanceData{
  data instData[];
};

layout(std430, binding = 2) buffer colData{
  vec4 colorData[];
};

out vec4 teamColor;
out vec3 fNormal;

void main(){
  data theData = instData[gl_InstanceID];
  gl_Position = VP * theData.model * vec4(vertex_position, 1);
  fNormal = mat3(theData.model) * normal;
  teamColor = colorData[theData.team];
}
