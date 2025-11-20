pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import qs.Helpers

Singleton {
    id: root

    readonly property M3TemplateComponent m3Colors: M3TemplateComponent {}

    FileView {
        id: colorsFile

        path: Paths.home + "/.config/shell/colors.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
    }

    ColorQuantizer {
        id: colorQuantizer

        source: Qt.resolvedUrl(Paths.currentWallpaper)
        depth: 2
        rescaleSize: 64
    }

    function getSourceColor() {
        if (colorQuantizer.colors.length === 0)
            return "#6750A4";
        let maxChroma = 0;
        let sourceColor = colorQuantizer.colors[0];

        for (let i = 0; i < Math.min(colorQuantizer.colors.length, 16); i++) {
            let color = colorQuantizer.colors[i];
            let chroma = calculateChroma(color);

            if (chroma > maxChroma) {
                maxChroma = chroma;
                sourceColor = color;
            }
        }

        return sourceColor;
    }

    function calculateChroma(color) {
        let r = color.r;
        let g = color.g;
        let b = color.b;

        let max = Math.max(r, g, b);
        let min = Math.min(r, g, b);

        return max - min;

    }

    function rgbToHsv(color) {
        let r = color.r;
        let g = color.g;
        let b = color.b;
        let max = Math.max(r, g, b);
        let min = Math.min(r, g, b);
        let delta = max - min;
        let h = 0, s = 0, v = max;

        if (delta !== 0) {
            s = delta / max;

            if (r === max) {
                h = ((g - b) / delta) % 6;
            } else if (g === max) {
                h = (b - r) / delta + 2;
            } else {
                h = (r - g) / delta + 4;
            }

            h = h * 60;

            if (h < 0)
                h += 360;
        }

        return {
            h: h,
            s: s,
            v: v
        };
    }

    function hsvToRgb(h, s, v) {
        let c = v * s;
        let x = c * (1 - Math.abs(((h / 60) % 2) - 1));
        let m = v - c;
        let r = 0, g = 0, b = 0;

        if (h >= 0 && h < 60) {
            r = c;
            g = x;
            b = 0;
        } else if (h >= 60 && h < 120) {
            r = x;
            g = c;
            b = 0;
        } else if (h >= 120 && h < 180) {
            r = 0;
            g = c;
            b = x;
        } else if (h >= 180 && h < 240) {
            r = 0;
            g = x;
            b = c;
        } else if (h >= 240 && h < 300) {
            r = x;
            g = 0;
            b = c;
        } else {
            r = c;
            g = 0;
            b = x;
        }
        return Qt.rgba(r + m, g + m, b + m, 1.0);
    }

    function createTonalColor(baseColor, tone) {
        let hsv = rgbToHsv(baseColor);

        let targetV = tone / 100.0;

        let targetS = hsv.s;
        if (tone < 30) {
            targetS = hsv.s * (0.3 + (tone / 100));
        } else if (tone > 90) {
            targetS = hsv.s * 0.2;
        } else if (tone < 50) {
            targetS = hsv.s * (0.6 + (tone / 200));
        } else {
            targetS = hsv.s * Math.min(1.0, 0.8 + (tone / 500));
        }

        return hsvToRgb(hsv.h, targetS, targetV);
    }

    function createAnalogousColor(baseColor, hueShift) {
        let hsv = rgbToHsv(baseColor);
        let newHue = (hsv.h + hueShift) % 360;
        if (newHue < 0)
            newHue += 360;
        return hsvToRgb(newHue, hsv.s, hsv.v);
    }

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    component M3TemplateComponent: QtObject {
        readonly property color m3SourceColor: root.getSourceColor()
        readonly property color m3SecondarySource: root.createAnalogousColor(m3SourceColor, 30)
        readonly property color m3TertiarySource: root.createAnalogousColor(m3SourceColor, 60)

        readonly property color m3NeutralSource: {
            let hsv = root.rgbToHsv(m3SourceColor);
            return root.hsvToRgb(hsv.h, hsv.s * 0.08, hsv.v);
        }
        readonly property color m3NeutralVariantSource: {
            let hsv = root.rgbToHsv(m3SourceColor);
            return root.hsvToRgb(hsv.h, hsv.s * 0.16, hsv.v);
        }

        readonly property color m3Background: root.createTonalColor(m3NeutralSource, 6)
        readonly property color m3Surface: root.createTonalColor(m3NeutralSource, 6)
        readonly property color m3SurfaceDim: root.createTonalColor(m3NeutralSource, 6)
        readonly property color m3SurfaceBright: root.createTonalColor(m3NeutralSource, 24)

        readonly property color m3SurfaceContainerLowest: root.createTonalColor(m3NeutralSource, 4)
        readonly property color m3SurfaceContainerLow: root.createTonalColor(m3NeutralSource, 10)
        readonly property color m3SurfaceContainer: root.createTonalColor(m3NeutralSource, 12)
        readonly property color m3SurfaceContainerHigh: root.createTonalColor(m3NeutralSource, 17)
        readonly property color m3SurfaceContainerHighest: root.createTonalColor(m3NeutralSource, 22)

        readonly property color m3OnSurface: root.createTonalColor(m3NeutralSource, 98)
        readonly property color m3OnSurfaceVariant: root.createTonalColor(m3NeutralVariantSource, 90)
        readonly property color m3OnBackground: root.createTonalColor(m3NeutralSource, 98)

        readonly property color m3Primary: root.createTonalColor(m3SourceColor, 80)
        readonly property color m3OnPrimary: root.createTonalColor(m3SourceColor, 20)
        readonly property color m3PrimaryContainer: root.createTonalColor(m3SourceColor, 30)
        readonly property color m3OnPrimaryContainer: root.createTonalColor(m3SourceColor, 98)

        readonly property color m3PrimaryFixed: root.createTonalColor(m3SourceColor, 90)
        readonly property color m3PrimaryFixedDim: root.createTonalColor(m3SourceColor, 80)
        readonly property color m3OnPrimaryFixed: root.createTonalColor(m3SourceColor, 10)
        readonly property color m3OnPrimaryFixedVariant: root.createTonalColor(m3SourceColor, 30)

        readonly property color m3Secondary: root.createTonalColor(m3SecondarySource, 80)
        readonly property color m3OnSecondary: root.createTonalColor(m3SecondarySource, 20)
        readonly property color m3SecondaryContainer: root.createTonalColor(m3SecondarySource, 30)
        readonly property color m3OnSecondaryContainer: root.createTonalColor(m3SecondarySource, 98)

        readonly property color m3SecondaryFixed: root.createTonalColor(m3SecondarySource, 90)
        readonly property color m3SecondaryFixedDim: root.createTonalColor(m3SecondarySource, 80)
        readonly property color m3OnSecondaryFixed: root.createTonalColor(m3SecondarySource, 10)
        readonly property color m3OnSecondaryFixedVariant: root.createTonalColor(m3SecondarySource, 30)

        readonly property color m3Tertiary: root.createTonalColor(m3TertiarySource, 80)
        readonly property color m3OnTertiary: root.createTonalColor(m3TertiarySource, 20)
        readonly property color m3TertiaryContainer: root.createTonalColor(m3TertiarySource, 30)
        readonly property color m3OnTertiaryContainer: root.createTonalColor(m3TertiarySource, 98)

        readonly property color m3TertiaryFixed: root.createTonalColor(m3TertiarySource, 90)
        readonly property color m3TertiaryFixedDim: root.createTonalColor(m3TertiarySource, 80)
        readonly property color m3OnTertiaryFixed: root.createTonalColor(m3TertiarySource, 10)
        readonly property color m3OnTertiaryFixedVariant: root.createTonalColor(m3TertiarySource, 30)

        readonly property color m3Error: "#F2B8B5"
        readonly property color m3ErrorContainer: "#8C1D18"
        readonly property color m3OnError: "#690005"
        readonly property color m3OnErrorContainer: "#ffdad6"

        readonly property color m3InverseSurface: root.createTonalColor(m3NeutralSource, 90)
        readonly property color m3InverseOnSurface: root.createTonalColor(m3NeutralSource, 20)
        readonly property color m3InversePrimary: root.createTonalColor(m3SourceColor, 40)

        readonly property color m3Outline: root.createTonalColor(m3NeutralVariantSource, 60)
        readonly property color m3OutlineVariant: root.createTonalColor(m3NeutralVariantSource, 30)

        readonly property color m3Scrim: "#000000"
        readonly property color m3Shadow: "#000000"
        readonly property color m3SurfaceTint: m3Primary
        readonly property color m3SurfaceVariant: root.createTonalColor(m3NeutralVariantSource, 30)

        readonly property color m3Red: m3Error
        readonly property color m3Green: "#4CAF50"
        readonly property color m3Blue: "#2196F3"
        readonly property color m3Yellow: "#FFC107"
    }
}
