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
    float edge = 1.0 - ubuf.progress;
    float t    = smoothstep(edge, edge + ubuf.smoothAmount, texCoord.y);
    vec3  col  = mix(
        texture(source1, texCoord).rgb,
        texture(source2, texCoord).rgb,
        t
    );
    fragColor = vec4(col, 1.0) * ubuf.qt_Opacity;
}
