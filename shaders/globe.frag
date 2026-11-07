#version 460 core

#include <flutter/runtime_effect.glsl>

// Orthographic globe: samples an equirectangular shaded-relief texture.
// Ocean pixels are left transparent so the painter's ocean gradient shows.

uniform vec2 uCenter;
uniform float uRadius;
uniform float uLat0;
uniform float uLng0;
uniform float uShade;
uniform sampler2D uTex;

out vec4 fragColor;

const float PI = 3.14159265358979;

void main() {
  vec2 p = FlutterFragCoord().xy;
  float x = (p.x - uCenter.x) / uRadius;
  float y = -(p.y - uCenter.y) / uRadius;
  float rho = sqrt(x * x + y * y);
  if (rho >= 1.0) {
    fragColor = vec4(0.0);
    return;
  }

  float lat;
  float lng;
  if (rho < 1e-6) {
    lat = uLat0;
    lng = uLng0;
  } else {
    float c = asin(rho);
    float sinC = sin(c);
    float cosC = cos(c);
    lat = asin(cosC * sin(uLat0) + y * sinC * cos(uLat0) / rho);
    lng = uLng0 + atan(x * sinC,
                       rho * cos(uLat0) * cosC - y * sin(uLat0) * sinC);
  }

  vec2 uv = vec2(fract((lng + PI) / (2.0 * PI)), (PI / 2.0 - lat) / PI);
  float g = texture(uTex, uv).r;

  // The texture paints water as a flat mid-gray (~0.416); land is brighter.
  float land = smoothstep(0.43, 0.46, g);
  float relief = clamp((g - 0.45) / 0.55, 0.0, 1.0);
  if (uShade > 0.5) {
    // Shading-only mode: a multiplier applied over flat country fills.
    float m = mix(0.62, 1.0, smoothstep(0.03, 0.55, relief));
    m = land > 0.5 ? m : 1.0;
    fragColor = vec4(vec3(m), 1.0);
    return;
  }

  vec3 low = vec3(0.20, 0.25, 0.33);
  vec3 high = vec3(0.66, 0.72, 0.80);
  vec3 color = mix(low, high, pow(relief, 0.8));

  fragColor = vec4(color * land, land);
}
