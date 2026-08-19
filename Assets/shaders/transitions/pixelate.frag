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
    float p    = ubuf.progress;

    float ramp    = (p < 0.5) ? p * 2.0 : (1.0 - p) * 2.0;
    // UV-space block size — 0.001 floor prevents divide-by-zero at p=0/1
    float blkSize = ramp * 0.06 + 0.001;

    // Snap uv to nearest block centre — no resolution uniform needed
    vec2 uv2 = floor(uv / blkSize) * blkSize + blkSize * 0.5;

    vec3 col = (p < 0.5)
        ? texture(source1, uv2).rgb
        : texture(source2, uv2).rgb;

    fragColor = vec4(col, 1.0) * ubuf.qt_Opacity;
}
