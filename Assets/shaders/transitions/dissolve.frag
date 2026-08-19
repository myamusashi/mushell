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

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec2  uv   = texCoord;
    float mask = step(hash21(uv), ubuf.progress);

    // Issue both fetches in parallel — GPU texture units handle simultaneously.
    vec3 c1  = texture(source1, uv).rgb;
    vec3 c2  = texture(source2, uv).rgb;
    vec3 col = mix(c1, c2, mask);

    fragColor = vec4(col, 1.0) * ubuf.qt_Opacity;
}
