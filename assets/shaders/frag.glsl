#version 430
out vec4 frag_colour;

in vec4 teamColor;
in vec3 fNormal;


void main() {
  frag_colour = teamColor;
  float light = dot(fNormal, normalize(vec3(0, 1, -0.5)));
  frag_colour *= round(light / 0.5) * 0.5;
}
