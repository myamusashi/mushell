#version 450

layout(location = 0) in  vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float effectWidth;
    float centerY;
    float activeEnd;
    vec4  activeColor;
    vec4  inactiveColor;
    float inactiveStart;
    float waveFrequency;
    float waveAmplitude;
    float wavePhase;
    float strokeHalfWidth;
};

void main() {
    const float PI2    = 6.283185307;
    const float fringe = 1.0;

    float px = qt_TexCoord0.x * effectWidth;
    float py = qt_TexCoord0.y * (centerY * 2.0);

    float waveY = centerY + waveAmplitude * sin((px / effectWidth) * PI2 * waveFrequency + wavePhase);
    float dWave = abs(py - waveY);
    float waveA = smoothstep(strokeHalfWidth + fringe,
                             max(strokeHalfWidth - fringe, 0.0), dWave);
    waveA *= step(0.0, px) * step(px, activeEnd);

    float dFlat = abs(py - centerY);
    float flatA = smoothstep(strokeHalfWidth + fringe,
                             max(strokeHalfWidth - fringe, 0.0), dFlat);
    flatA *= step(inactiveStart, px) * step(px, effectWidth);

    float aA = activeColor.a   * waveA * qt_Opacity;
    float iA = inactiveColor.a * flatA * qt_Opacity;

    fragColor = vec4(activeColor.rgb * aA, aA)
              + vec4(inactiveColor.rgb * iA, iA);
}
