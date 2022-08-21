#version 430
layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 uv;
uniform mat4 VP;

struct data{
  vec3 pos;
  int team;
};

layout(std430, binding = 1) buffer instanceData{
  data instData[];
};

layout(std430, binding = 2) buffer colData{
  vec4 colorData[];
};

out vec4 teamColor;

void main(){
  data theData = instData[gl_InstanceID];
  gl_Position = VP * vec4(vertex_position + theData.pos, 1);
  teamColor = colorData[theData.team];
}
