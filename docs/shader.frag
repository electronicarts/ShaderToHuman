#ifdef GL_ES
precision mediump float;
#endif

void main() {
  gl_FragColor = vec4(gl_FragCoord.xy / vec2(800.0, 600.0), 0.5, 1.0);
}
