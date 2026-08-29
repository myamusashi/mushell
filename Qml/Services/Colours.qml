pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import Vast.Utils

Singleton {
    id: root

    readonly property M3GeneratedTemplateComponent m3GeneratedColors: M3GeneratedTemplateComponent {}
    readonly property MaterialTemplateComponent materialColors: MaterialTemplateComponent {}
    readonly property StaticColorTemplateComponent staticColors: StaticColorTemplateComponent {}
    readonly property var materialTemplateColors: root.animatedMaterialColors
    readonly property var staticTemplateColors: JSON.parse(staticColorFile.text())
    readonly property M3TemplateColors m3Colors: Configs.colors.useMaterialColor ? materialColors : Configs.colors.useStaticColors ? staticColors : m3GeneratedColors

    readonly property string wallpaperSource: {
        const wp = GlobalStates.previewWallpaper !== "" ? GlobalStates.previewWallpaper : Paths.currentWallpaper;
        if (!wp)
            return "";
        return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(wp) ? `${Paths.cacheDir}/vast-shell/vast-wallpaper-${Qt.md5(wp)}.png` : wp;
    }

    readonly property var materialPaletteSource: materialColor.ready ? materialColor.colors : root.lastValidPalette
    property var lastValidPalette: ({})

    readonly property alias animatedMaterialColors: paletteAnimator.currentPalette

    function schemeEnum(name) {
        switch (name) {
        case "vibrant":
            return ColorMaterial.Vibrant;
        case "expressive":
            return ColorMaterial.Expressive;
        case "monochrome":
            return ColorMaterial.Monochrome;
        case "rainbow":
            return ColorMaterial.Rainbow;
        case "fruit-salad":
            return ColorMaterial.FruitSalad;
        case "neutral":
            return ColorMaterial.Neutral;
        case "fidelity":
            return ColorMaterial.Fidelity;
        case "content":
            return ColorMaterial.Content;
        default:
            return ColorMaterial.TonalSpot;
        }
    }

    onMaterialPaletteSourceChanged: {
        if (!root.materialPaletteSource || Object.keys(root.materialPaletteSource).length === 0)
            return;
        root.lastValidPalette = root.materialPaletteSource;
        paletteAnimator.transitionTo(root.materialPaletteSource);
    }

    Component.onCompleted: {
        if (root.materialPaletteSource && Object.keys(root.materialPaletteSource).length > 0)
            paletteAnimator.transitionTo(root.materialPaletteSource);
    }

    function clamp01(x) {
        return Math.min(1, Math.max(0, x));
    }

    function blendColors(src: color, dst: color, t: double): color {
        return ColorUtils.blendColors(src, dst, t);
    }

    function overlayColor(baseColor, targetColor, overlayOpacity) {
        if (overlayOpacity <= 0)
            // Impossible to influence the base
            return Qt.rgba(0, 0, 0, 0);

        let invA = 1.0 - overlayOpacity;

        let r = (targetColor.r - baseColor.r * invA) / overlayOpacity;
        let g = (targetColor.g - baseColor.g * invA) / overlayOpacity;
        let b = (targetColor.b - baseColor.b * invA) / overlayOpacity;

        return Qt.rgba(clamp01(r), clamp01(g), clamp01(b), 1.0);
    }

    function rgbToHct(color) {
        return ColorUtils.rgbToHct(color);
    }

    function hctToRgb(h, c, t) {
        return ColorUtils.hctToRgb(h, c, t);
    }

    function createTonalColor(baseColor, tone) {
        return ColorUtils.createTonalColor(baseColor, tone);
    }

    function createAnalogousColor(baseColor, hueShift) {
        return ColorUtils.createAnalogousColor(baseColor, hueShift);
    }

    FileView {
        id: staticColorFile

        path: Configs.colors.staticColorsPath
        watchChanges: true
        onFileChanged: reload()
    }

    ColorMaterial {
        id: materialColor

        source: root.wallpaperSource !== "" ? `file://${root.wallpaperSource}` : ""
        darkMode: Configs.colors.isDarkMode
        scheme: root.schemeEnum(Configs.colors.scheme)
    }

    PaletteAnimator {
        id: paletteAnimator
        duration: Appearance.animations.durations.expressiveDefaultSpatial
    }

    component StaticColorTemplateComponent: M3TemplateColors {
        readonly property color m3Background: root.staticTemplateColors.background
        readonly property color m3Surface: root.staticTemplateColors.surface
        readonly property color m3SurfaceDim: root.staticTemplateColors.surfaceDim
        readonly property color m3SurfaceBright: root.staticTemplateColors.surfaceBright
        readonly property color m3SurfaceContainerLowest: root.staticTemplateColors.surfaceContainerLowest
        readonly property color m3SurfaceContainerLow: root.staticTemplateColors.surfaceContainerLow
        readonly property color m3SurfaceContainer: root.staticTemplateColors.surfaceContainer
        readonly property color m3SurfaceContainerHigh: root.staticTemplateColors.surfaceContainerHigh
        readonly property color m3SurfaceContainerHighest: root.staticTemplateColors.surfaceContainerHighest

        readonly property color m3OnSurface: root.staticTemplateColors.onSurface
        readonly property color m3OnSurfaceVariant: root.staticTemplateColors.onSurfaceVariant
        readonly property color m3OnBackground: root.staticTemplateColors.onBackground

        readonly property color m3Primary: root.staticTemplateColors.primary
        readonly property color m3OnPrimary: root.staticTemplateColors.onPrimary
        readonly property color m3PrimaryContainer: root.staticTemplateColors.primaryContainer
        readonly property color m3OnPrimaryContainer: root.staticTemplateColors.onPrimaryContainer
        readonly property color m3PrimaryFixed: root.staticTemplateColors.primaryFixed
        readonly property color m3PrimaryFixedDim: root.staticTemplateColors.primaryFixedDim
        readonly property color m3OnPrimaryFixed: root.staticTemplateColors.onPrimaryFixed
        readonly property color m3OnPrimaryFixedVariant: root.staticTemplateColors.onPrimaryFixedVariant

        readonly property color m3Secondary: root.staticTemplateColors.secondary
        readonly property color m3OnSecondary: root.staticTemplateColors.onSecondary
        readonly property color m3SecondaryContainer: root.staticTemplateColors.secondaryContainer
        readonly property color m3OnSecondaryContainer: root.staticTemplateColors.onSecondaryContainer
        readonly property color m3SecondaryFixed: root.staticTemplateColors.secondaryFixed
        readonly property color m3SecondaryFixedDim: root.staticTemplateColors.secondaryFixedDim
        readonly property color m3OnSecondaryFixed: root.staticTemplateColors.onSecondaryFixed
        readonly property color m3OnSecondaryFixedVariant: root.staticTemplateColors.onSecondaryFixedVariant

        readonly property color m3Tertiary: root.staticTemplateColors.tertiary
        readonly property color m3OnTertiary: root.staticTemplateColors.onTertiary
        readonly property color m3TertiaryContainer: root.staticTemplateColors.tertiaryContainer
        readonly property color m3OnTertiaryContainer: root.staticTemplateColors.onTertiaryContainer
        readonly property color m3TertiaryFixed: root.staticTemplateColors.tertiaryFixed
        readonly property color m3TertiaryFixedDim: root.staticTemplateColors.tertiaryFixedDim
        readonly property color m3OnTertiaryFixed: root.staticTemplateColors.onTertiaryFixed
        readonly property color m3OnTertiaryFixedVariant: root.staticTemplateColors.onTertiaryFixedVariant

        readonly property color m3Error: root.staticTemplateColors.error
        readonly property color m3ErrorContainer: root.staticTemplateColors.errorContainer
        readonly property color m3OnError: root.staticTemplateColors.onError
        readonly property color m3OnErrorContainer: root.staticTemplateColors.onErrorContainer

        readonly property color m3InverseSurface: root.staticTemplateColors.inverseSurface
        readonly property color m3InverseOnSurface: root.staticTemplateColors.inverseOnSurface
        readonly property color m3InversePrimary: root.staticTemplateColors.inversePrimary

        readonly property color m3Outline: root.staticTemplateColors.outline
        readonly property color m3OutlineVariant: root.staticTemplateColors.outlineVariant

        readonly property color m3Scrim: root.staticTemplateColors.scrim
        readonly property color m3Shadow: root.staticTemplateColors.shadow
        readonly property color m3SurfaceTint: root.staticTemplateColors.surfaceTint
        readonly property color m3SurfaceVariant: root.staticTemplateColors.surfaceVariant

        readonly property color m3Red: m3Error
        readonly property color m3Green: root.hctToRgb(145, 50, 70)
        readonly property color m3Blue: root.hctToRgb(220, 50, 70)
        readonly property color m3Yellow: root.hctToRgb(90, 60, 70)
        readonly property color m3Orange: root.hctToRgb(30, 50, 70)
        readonly property color m3Purple: root.hctToRgb(285, 50, 70)
        readonly property color m3Maroon: root.hctToRgb(10, 30, 30)
    }

    component MaterialTemplateComponent: M3TemplateColors {
        readonly property color m3Background: root.materialTemplateColors.background
        readonly property color m3Surface: root.materialTemplateColors.surface
        readonly property color m3SurfaceDim: root.materialTemplateColors.surfaceDim
        readonly property color m3SurfaceBright: root.materialTemplateColors.surfaceBright
        readonly property color m3SurfaceContainerLowest: root.materialTemplateColors.surfaceContainerLowest
        readonly property color m3SurfaceContainerLow: root.materialTemplateColors.surfaceContainerLow
        readonly property color m3SurfaceContainer: root.materialTemplateColors.surfaceContainer
        readonly property color m3SurfaceContainerHigh: root.materialTemplateColors.surfaceContainerHigh
        readonly property color m3SurfaceContainerHighest: root.materialTemplateColors.surfaceContainerHighest

        readonly property color m3OnSurface: root.materialTemplateColors.onSurface
        readonly property color m3OnSurfaceVariant: root.materialTemplateColors.onSurfaceVariant
        readonly property color m3OnBackground: root.materialTemplateColors.onBackground

        readonly property color m3Primary: root.materialTemplateColors.primary
        readonly property color m3OnPrimary: root.materialTemplateColors.onPrimary
        readonly property color m3PrimaryContainer: root.materialTemplateColors.primaryContainer
        readonly property color m3OnPrimaryContainer: root.materialTemplateColors.onPrimaryContainer
        readonly property color m3PrimaryFixed: root.materialTemplateColors.primaryFixed
        readonly property color m3PrimaryFixedDim: root.materialTemplateColors.primaryFixedDim
        readonly property color m3OnPrimaryFixed: root.materialTemplateColors.onPrimaryFixed
        readonly property color m3OnPrimaryFixedVariant: root.materialTemplateColors.onPrimaryFixedVariant

        readonly property color m3Secondary: root.materialTemplateColors.secondary
        readonly property color m3OnSecondary: root.materialTemplateColors.onSecondary
        readonly property color m3SecondaryContainer: root.materialTemplateColors.secondaryContainer
        readonly property color m3OnSecondaryContainer: root.materialTemplateColors.onSecondaryContainer
        readonly property color m3SecondaryFixed: root.materialTemplateColors.secondaryFixed
        readonly property color m3SecondaryFixedDim: root.materialTemplateColors.secondaryFixedDim
        readonly property color m3OnSecondaryFixed: root.materialTemplateColors.onSecondaryFixed
        readonly property color m3OnSecondaryFixedVariant: root.materialTemplateColors.onSecondaryFixedVariant

        readonly property color m3Tertiary: root.materialTemplateColors.tertiary
        readonly property color m3OnTertiary: root.materialTemplateColors.onTertiary
        readonly property color m3TertiaryContainer: root.materialTemplateColors.tertiaryContainer
        readonly property color m3OnTertiaryContainer: root.materialTemplateColors.onTertiaryContainer
        readonly property color m3TertiaryFixed: root.materialTemplateColors.tertiaryFixed
        readonly property color m3TertiaryFixedDim: root.materialTemplateColors.tertiaryFixedDim
        readonly property color m3OnTertiaryFixed: root.materialTemplateColors.onTertiaryFixed
        readonly property color m3OnTertiaryFixedVariant: root.materialTemplateColors.onTertiaryFixedVariant

        readonly property color m3Error: root.materialTemplateColors.error
        readonly property color m3ErrorContainer: root.materialTemplateColors.errorContainer
        readonly property color m3OnError: root.materialTemplateColors.onError
        readonly property color m3OnErrorContainer: root.materialTemplateColors.onErrorContainer

        readonly property color m3InverseSurface: root.materialTemplateColors.inverseSurface
        readonly property color m3InverseOnSurface: root.materialTemplateColors.inverseOnSurface
        readonly property color m3InversePrimary: root.materialTemplateColors.inversePrimary

        readonly property color m3Outline: root.materialTemplateColors.outline
        readonly property color m3OutlineVariant: root.materialTemplateColors.outlineVariant

        readonly property color m3Scrim: root.materialTemplateColors.scrim
        readonly property color m3Shadow: root.materialTemplateColors.shadow
        readonly property color m3SurfaceTint: root.materialTemplateColors.surfaceTint
        readonly property color m3SurfaceVariant: root.materialTemplateColors.surfaceVariant

        readonly property color m3Red: m3Error
        readonly property color m3Green: root.hctToRgb(145, 50, 70)
        readonly property color m3Blue: root.hctToRgb(220, 50, 70)
        readonly property color m3Yellow: root.hctToRgb(90, 60, 70)
        readonly property color m3Orange: root.hctToRgb(30, 50, 70)
        readonly property color m3Purple: root.hctToRgb(285, 50, 70)
        readonly property color m3Maroon: root.hctToRgb(10, 30, 30)
    }

    component M3GeneratedTemplateComponent: M3TemplateColors {
        readonly property color m3SourceColor: {
            const sourceColor = root.materialTemplateColors.sourceColor;
            return sourceColor ? sourceColor : "#6750A4";
        }
        readonly property color m3SecondarySource: root.createAnalogousColor(m3SourceColor, 60)
        readonly property color m3TertiarySource: root.createAnalogousColor(m3SourceColor, 120)
        readonly property color m3NeutralSource: {
            let hct = root.rgbToHct(m3SourceColor);
            return root.hctToRgb(hct.h, 4, hct.t);
        }
        readonly property color m3NeutralVariantSource: {
            let hct = root.rgbToHct(m3SourceColor);
            return root.hctToRgb(hct.h, 8, hct.t);
        }

        readonly property color m3Background: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 6 : 98)
        readonly property color m3Surface: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 6 : 98)
        readonly property color m3SurfaceDim: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 6 : 87)
        readonly property color m3SurfaceBright: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 24 : 98)
        readonly property color m3SurfaceContainerLowest: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 4 : 100)
        readonly property color m3SurfaceContainerLow: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 10 : 96)
        readonly property color m3SurfaceContainer: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 12 : 94)
        readonly property color m3SurfaceContainerHigh: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 17 : 92)
        readonly property color m3SurfaceContainerHighest: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 22 : 90)

        readonly property color m3OnSurface: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 90 : 10)
        readonly property color m3OnSurfaceVariant: root.createTonalColor(m3NeutralVariantSource, Configs.colors.isDarkMode ? 80 : 30)
        readonly property color m3OnBackground: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 90 : 10)

        readonly property color m3Primary: root.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 80 : 40)
        readonly property color m3OnPrimary: root.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 20 : 100)
        readonly property color m3PrimaryContainer: root.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 30 : 90)
        readonly property color m3OnPrimaryContainer: root.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 90 : 10)
        readonly property color m3PrimaryFixed: root.createTonalColor(m3SourceColor, 90)
        readonly property color m3PrimaryFixedDim: root.createTonalColor(m3SourceColor, 80)
        readonly property color m3OnPrimaryFixed: root.createTonalColor(m3SourceColor, 10)
        readonly property color m3OnPrimaryFixedVariant: root.createTonalColor(m3SourceColor, 30)

        readonly property color m3Secondary: root.createTonalColor(m3SecondarySource, Configs.colors.isDarkMode ? 80 : 40)
        readonly property color m3OnSecondary: root.createTonalColor(m3SecondarySource, Configs.colors.isDarkMode ? 20 : 100)
        readonly property color m3SecondaryContainer: root.createTonalColor(m3SecondarySource, Configs.colors.isDarkMode ? 30 : 90)
        readonly property color m3OnSecondaryContainer: root.createTonalColor(m3SecondarySource, Configs.colors.isDarkMode ? 90 : 10)
        readonly property color m3SecondaryFixed: root.createTonalColor(m3SecondarySource, 90)
        readonly property color m3SecondaryFixedDim: root.createTonalColor(m3SecondarySource, 80)
        readonly property color m3OnSecondaryFixed: root.createTonalColor(m3SecondarySource, 10)
        readonly property color m3OnSecondaryFixedVariant: root.createTonalColor(m3SecondarySource, 30)

        readonly property color m3Tertiary: root.createTonalColor(m3TertiarySource, Configs.colors.isDarkMode ? 80 : 40)
        readonly property color m3OnTertiary: root.createTonalColor(m3TertiarySource, Configs.colors.isDarkMode ? 20 : 100)
        readonly property color m3TertiaryContainer: root.createTonalColor(m3TertiarySource, Configs.colors.isDarkMode ? 30 : 90)
        readonly property color m3OnTertiaryContainer: root.createTonalColor(m3TertiarySource, Configs.colors.isDarkMode ? 90 : 10)
        readonly property color m3TertiaryFixed: root.createTonalColor(m3TertiarySource, 90)
        readonly property color m3TertiaryFixedDim: root.createTonalColor(m3TertiarySource, 80)
        readonly property color m3OnTertiaryFixed: root.createTonalColor(m3TertiarySource, 10)
        readonly property color m3OnTertiaryFixedVariant: root.createTonalColor(m3TertiarySource, 30)

        readonly property color m3ErrorSource: root.hctToRgb(25, 84, 40)
        readonly property color m3Error: root.createTonalColor(m3ErrorSource, Configs.colors.isDarkMode ? 80 : 40)
        readonly property color m3ErrorContainer: root.createTonalColor(m3ErrorSource, Configs.colors.isDarkMode ? 30 : 90)
        readonly property color m3OnError: root.createTonalColor(m3ErrorSource, Configs.colors.isDarkMode ? 20 : 100)
        readonly property color m3OnErrorContainer: root.createTonalColor(m3ErrorSource, Configs.colors.isDarkMode ? 90 : 10)

        readonly property color m3InverseSurface: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 90 : 20)
        readonly property color m3InverseOnSurface: root.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 20 : 95)
        readonly property color m3InversePrimary: root.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 40 : 80)

        readonly property color m3Outline: root.createTonalColor(m3NeutralVariantSource, Configs.colors.isDarkMode ? 60 : 50)
        readonly property color m3OutlineVariant: root.createTonalColor(m3NeutralVariantSource, Configs.colors.isDarkMode ? 30 : 80)

        readonly property color m3Scrim: "#000000"
        readonly property color m3Shadow: "#000000"
        readonly property color m3SurfaceTint: m3Primary
        readonly property color m3SurfaceVariant: root.createTonalColor(m3NeutralVariantSource, Configs.colors.isDarkMode ? 30 : 90)

        readonly property color m3Red: m3Error
        readonly property color m3Green: root.hctToRgb(145, 50, Configs.colors.isDarkMode ? 70 : 40)
        readonly property color m3Blue: root.hctToRgb(220, 50, Configs.colors.isDarkMode ? 70 : 40)
        readonly property color m3Yellow: root.hctToRgb(90, 60, Configs.colors.isDarkMode ? 70 : 40)
        readonly property color m3Orange: root.hctToRgb(30, 50, Configs.colors.isDarkMode ? 70 : 40)
        readonly property color m3Purple: root.hctToRgb(285, 50, Configs.colors.isDarkMode ? 70 : 40)
        readonly property color m3Maroon: root.hctToRgb(10, 40, Configs.colors.isDarkMode ? 45 : 30)
    }

    component M3TemplateColors: QtObject {
        readonly property color m3Background: "transparent"
        readonly property color m3Surface: "transparent"
        readonly property color m3SurfaceDim: "transparent"
        readonly property color m3SurfaceBright: "transparent"
        readonly property color m3SurfaceContainerLowest: "transparent"
        readonly property color m3SurfaceContainerLow: "transparent"
        readonly property color m3SurfaceContainer: "transparent"
        readonly property color m3SurfaceContainerHigh: "transparent"
        readonly property color m3SurfaceContainerHighest: "transparent"
        readonly property color m3OnSurface: "transparent"
        readonly property color m3OnSurfaceVariant: "transparent"
        readonly property color m3OnBackground: "transparent"
        readonly property color m3Primary: "transparent"
        readonly property color m3OnPrimary: "transparent"
        readonly property color m3PrimaryContainer: "transparent"
        readonly property color m3OnPrimaryContainer: "transparent"
        readonly property color m3PrimaryFixed: "transparent"
        readonly property color m3PrimaryFixedDim: "transparent"
        readonly property color m3OnPrimaryFixed: "transparent"
        readonly property color m3OnPrimaryFixedVariant: "transparent"
        readonly property color m3Secondary: "transparent"
        readonly property color m3OnSecondary: "transparent"
        readonly property color m3SecondaryContainer: "transparent"
        readonly property color m3OnSecondaryContainer: "transparent"
        readonly property color m3SecondaryFixed: "transparent"
        readonly property color m3SecondaryFixedDim: "transparent"
        readonly property color m3OnSecondaryFixed: "transparent"
        readonly property color m3OnSecondaryFixedVariant: "transparent"
        readonly property color m3Tertiary: "transparent"
        readonly property color m3OnTertiary: "transparent"
        readonly property color m3TertiaryContainer: "transparent"
        readonly property color m3OnTertiaryContainer: "transparent"
        readonly property color m3TertiaryFixed: "transparent"
        readonly property color m3TertiaryFixedDim: "transparent"
        readonly property color m3OnTertiaryFixed: "transparent"
        readonly property color m3OnTertiaryFixedVariant: "transparent"
        readonly property color m3Error: "transparent"
        readonly property color m3ErrorContainer: "transparent"
        readonly property color m3OnError: "transparent"
        readonly property color m3OnErrorContainer: "transparent"
        readonly property color m3InverseSurface: "transparent"
        readonly property color m3InverseOnSurface: "transparent"
        readonly property color m3InversePrimary: "transparent"
        readonly property color m3Outline: "transparent"
        readonly property color m3OutlineVariant: "transparent"
        readonly property color m3Scrim: "transparent"
        readonly property color m3Shadow: "transparent"
        readonly property color m3SurfaceTint: "transparent"
        readonly property color m3SurfaceVariant: "transparent"
        readonly property color m3Red: "transparent"
        readonly property color m3Green: "transparent"
        readonly property color m3Blue: "transparent"
        readonly property color m3Yellow: "transparent"
        readonly property color m3Orange: "transparent"
        readonly property color m3Purple: "transparent"
        readonly property color m3Maroon: "transparent"
    }
}
