#version 450

layout(location = 0) noperspective in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform VertBuf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    float smoothAmount;
    float aspect;
    vec2  resolution;
    vec2  invResolution;
} ubuf;

layout(binding = 1) uniform sampler2D source1;
layout(binding = 2) uniform sampler2D source2;

void main() {
    vec2  uv    = texCoord;
    float p     = ubuf.progress;

    // Roll edge sweeps left-to-right: right side reveals source2 first
    float edge  = 1.0 - p;   // leading edge in UV X, starts at 1, ends at 0

    // Soft crease width
    float crease = 0.08;

    if (uv.x > edge + crease) {
        // Fully revealed — show incoming image
        fragColor = texture(source2, uv) * ubuf.qt_Opacity;
    } else if (uv.x > edge) {
        // Inside the crease — blend with a shading gradient to sell the curl
        float t     = (uv.x - edge) / crease;
        float shade = 1.0 - t * 0.45;   // darken the curl surface
        vec4  c1    = texture(source1, uv);
        vec4  c2    = texture(source2, uv);
        fragColor   = mix(c1 * shade, c2, smoothstep(0.0, 1.0, t)) * ubuf.qt_Opacity;
    } else {
        // Not yet rolled — show outgoing image, slight shadow near crease
        float shadow = smoothstep(0.0, crease * 2.0, uv.x - edge + crease * 2.0);
        fragColor = texture(source1, uv) * (0.75 + 0.25 * shadow) * ubuf.qt_Opacity;
    }
}
