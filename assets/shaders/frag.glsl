#version 430
out vec4 frag_colour;
in vec4 teamColor;

void main() {
  frag_colour = teamColor;
}
