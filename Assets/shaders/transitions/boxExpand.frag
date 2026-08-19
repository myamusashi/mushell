#version 450

layout(location = 0) noperspective in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform VertBuf {
    mat4  qt_Matrix;     // offset  0
    float qt_Opacity;    // offset 64
    float progress;      // offset 68
    float smoothAmount;  // offset 72
    float aspect;        // offset 76
    vec2  resolution;    // offset 80
    vec2  invResolution; // offset 88
} ubuf;

layout(binding = 1) uniform sampler2D source1;
layout(binding = 2) uniform sampler2D source2;

void main() {
    vec2  uv   = texCoord;
    float maxD = max(abs(uv.x - 0.5), abs(uv.y - 0.5));
    float hs   = 0.5 * ubuf.progress;
    float t    = smoothstep(hs + ubuf.smoothAmount, hs, maxD);
    vec3  col  = mix(
        texture(source1, uv).rgb,
        texture(source2, uv).rgb,
        t
    );
    fragColor = vec4(col, 1.0) * ubuf.qt_Opacity;
}
