#version 450

layout(location = 0) noperspective in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform FragBuf {
    mat4  qt_Matrix;      // offset  0
    float qt_Opacity;     // offset 64
    float progress;       // offset 68
    float smoothAmount;   // offset 72
    float aspect;         // offset 76
    vec2  resolution;     // offset 80
    vec2  invResolution;  // offset 88
} ubuf;

layout(binding = 1) uniform sampler2D source1;
layout(binding = 2) uniform sampler2D source2;

void main() {
    float progress = ubuf.progress;
    float edge     = 1.0 - progress;

    // Boundary between old and new content, in normalized UV space.
    float inNew = step(edge, texCoord.y);

    // Clamp shifted sample so we never read past the top edge of source1.
    vec2 shiftedUV = vec2(texCoord.x, min(texCoord.y + progress, 1.0));

    vec3 fromColor = texture(source1, shiftedUV).rgb;
    vec3 toColor   = texture(source2, texCoord).rgb;
    vec3 color     = mix(fromColor, toColor, inNew);

    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
