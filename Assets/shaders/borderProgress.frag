#version 450

layout(location = 0) noperspective in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform VertBuf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    float radius;
    float borderWidth;
    vec2  resolution;
    vec4  borderColor;
} ubuf;

layout(binding = 1) uniform sampler2D source;

// centered at origin
float roundedRectSDF(vec2 p, vec2 halfSize, float r) {
    vec2 d = abs(p) - halfSize + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

// compute perimeter position [0..1] clockwise from top-center
float perimeterPosition(vec2 p, vec2 halfSize, float r) {
    // prevent artifacts
    float cr = min(r, min(halfSize.x, halfSize.y));

	// corner
    vec2 cTR = vec2( halfSize.x - cr,  halfSize.y - cr);
    vec2 cBR = vec2( halfSize.x - cr, -halfSize.y + cr);
    vec2 cBL = vec2(-halfSize.x + cr, -halfSize.y + cr);
    vec2 cTL = vec2(-halfSize.x + cr,  halfSize.y - cr);

    float topLen    = 2.0 * (halfSize.x - cr);
    float rightLen  = 2.0 * (halfSize.y - cr);
    float bottomLen = topLen;
    float leftLen   = rightLen;

    float arcLen = 0.5 * 3.14159265 * cr;

    float totalPerimeter = topLen + rightLen + bottomLen + leftLen + 4.0 * arcLen;

    // clockwise from top-center
    float dist = 0.0;

    // top edge, right half: from (0, halfSize.y) → (halfSize.x - cr, halfSize.y)
    float seg1 = topLen * 0.5;
    if (p.y >= cTR.y && p.x >= 0.0 && p.x <= cTR.x) {
        return (p.x / seg1 * seg1) / totalPerimeter;
    }
    dist += seg1;

    // top-right arc
    if (p.x >= cTR.x && p.y >= cTR.y) {
        vec2 d = p - cTR;
        float angle = atan(d.x, d.y); // 0 at top, PI/2 at right
        return (dist + angle / (0.5 * 3.14159265) * arcLen) / totalPerimeter;
    }
    dist += arcLen;

    // right edge
    if (p.x >= cTR.x && p.y <= cTR.y && p.y >= cBR.y) {
        float t = (cTR.y - p.y) / max(rightLen, 0.001);
        return (dist + t * rightLen) / totalPerimeter;
    }
    dist += rightLen;

    // bottom-right arc
    if (p.x >= cBR.x && p.y <= cBR.y) {
        vec2 d = p - cBR;
        float angle = atan(-d.y, d.x); // 0 at right, PI/2 at bottom
        return (dist + angle / (0.5 * 3.14159265) * arcLen) / totalPerimeter;
    }
    dist += arcLen;

    // bottom edge
    if (p.y <= -halfSize.y + cr && p.x <= cBR.x && p.x >= cBL.x) {
        float t = (cBR.x - p.x) / max(bottomLen, 0.001);
        return (dist + t * bottomLen) / totalPerimeter;
    }
    dist += bottomLen;

    // bottom-left arc
    if (p.x <= cBL.x && p.y <= cBL.y) {
        vec2 d = p - cBL;
        float angle = atan(-d.x, -d.y); // 0 at bottom, PI/2 at left
        return (dist + angle / (0.5 * 3.14159265) * arcLen) / totalPerimeter;
    }
    dist += arcLen;

    // left edge
    if (p.x <= cTL.x && p.y >= cTL.y || (p.x <= -halfSize.x + cr && p.y >= cBL.y && p.y <= cTL.y)) {
        float t = (p.y - cBL.y) / max(leftLen, 0.001);
        return (dist + t * leftLen) / totalPerimeter;
    }
    dist += leftLen;

    // top-left arc
    if (p.x <= cTL.x && p.y >= cTL.y) {
        vec2 d = p - cTL;
        float angle = atan(d.y, -d.x); // 0 at left, PI/2 at top
        return (dist + angle / (0.5 * 3.14159265) * arcLen) / totalPerimeter;
    }
    dist += arcLen;

    // top edge, left half: from (-halfSize.x + cr, halfSize.y) → (0, halfSize.y)
    if (p.y >= cTL.y && p.x >= cTL.x && p.x <= 0.0) {
        float t = (p.x - cTL.x) / max(seg1, 0.001);
        return (dist + t * seg1) / totalPerimeter;
    }

    return dist / totalPerimeter;
}

void main() {
    vec2 resolution = ubuf.resolution;
    vec2 halfSize = resolution * 0.5;

    // convert UV [0,1] to centered pixel coordinates
    vec2 uv = texCoord;
    vec2 p = (uv - 0.5) * resolution;

    // flip Y so top is positive
    p.y = -p.y;

    float r = ubuf.radius;
    float bw = ubuf.borderWidth;

    float outer = roundedRectSDF(p, halfSize, r);
    float inner = roundedRectSDF(p, halfSize - bw, max(r - bw, 0.0));

    float borderMask = smoothstep(0.5, -0.5, outer) * smoothstep(-0.5, 0.5, inner);

    if (borderMask < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // perimeter position [0..1] clockwise from top-center
    float t = perimeterPosition(p, halfSize, r);

    // show border where t < progress
    float edge = 2.0 / max(halfSize.x + halfSize.y, 1.0);
    float progressMask = smoothstep(ubuf.progress + edge, ubuf.progress - edge, t);

    fragColor = ubuf.borderColor * borderMask * progressMask * ubuf.qt_Opacity;
}
