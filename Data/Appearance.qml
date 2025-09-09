pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	component ColorsComponent: QtObject {
        readonly property color background: "#111318"
        readonly property color error: "#ffb4ab"
        readonly property color error_container: "#93000a"
        readonly property color inverse_on_surface: "#2e3036"
        readonly property color inverse_primary: "#425e91"
        readonly property color inverse_surface: "#e2e2e9"
        readonly property color on_background: "#e2e2e9"
        readonly property color on_error: "#690005"
        readonly property color on_error_container: "#ffdad6"
        readonly property color on_primary: "#0d2f5f"
        readonly property color on_primary_container: "#d7e2ff"
        readonly property color on_primary_fixed: "#001b3f"
        readonly property color on_primary_fixed_variant: "#294677"
        readonly property color on_secondary: "#283041"
        readonly property color on_secondary_container: "#dae2f9"
        readonly property color on_secondary_fixed: "#131c2c"
        readonly property color on_secondary_fixed_variant: "#3e4759"
        readonly property color on_surface: "#e2e2e9"
        readonly property color on_surface_variant: "#c4c6d0"
        readonly property color on_tertiary: "#3f2844"
        readonly property color on_tertiary_container: "#fad8fc"
        readonly property color on_tertiary_fixed: "#29132e"
        readonly property color on_tertiary_fixed_variant: "#573e5b"
        readonly property color outline: "#8e9099"
        readonly property color outline_variant: "#44474e"
        readonly property color primary: "#abc7ff"
        readonly property color primary_container: "#294677"
        readonly property color primary_fixed: "#d7e2ff"
        readonly property color primary_fixed_dim: "#abc7ff"
        readonly property color scrim: "#000000"
        readonly property color secondary: "#bec6dc"
        readonly property color secondary_container: "#3e4759"
        readonly property color secondary_fixed: "#dae2f9"
        readonly property color secondary_fixed_dim: "#bec6dc"
        readonly property color shadow: "#000000"
        readonly property color surface: "#111318"
        readonly property color surface_bright: "#37393e"
        readonly property color surface_container: "#1e2025"
        readonly property color surface_container_high: "#282a2f"
        readonly property color surface_container_highest: "#33353a"
        readonly property color surface_container_low: "#1a1c20"
        readonly property color surface_container_lowest: "#0c0e13"
        readonly property color surface_dim: "#111318"
        readonly property color surface_tint: "#abc7ff"
        readonly property color surface_variant: "#44474e"
        readonly property color tertiary: "#ddbce0"
        readonly property color tertiary_container: "#573e5b"
        readonly property color tertiary_fixed: "#fad8fc"
        readonly property color tertiary_fixed_dim: "#ddbce0"

        function withAlpha(color, alpha) {
            return Qt.rgba(color.r, color.g, color.b, alpha);
        }
    }

    component FontsComponent: QtObject {
        readonly property string family_Clock: "14 SegmentLED"
        readonly property string family_Material: "Material Symbols Rounded"
        readonly property string family_Mono: "Hack"
        readonly property string family_Sans: "Rubik"

        readonly property real fontScale: 1.0

        readonly property real small: 11 * fontScale
        readonly property real medium: 12 * fontScale
        readonly property real normal: 13 * fontScale
        readonly property real large: 15 * fontScale
        readonly property real larger: 17 * fontScale
        readonly property real extraLarge: 28 * fontScale
    }

    component AnimationCurvesComponent: QtObject {
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    }

    component AnimationDurationsComponent: QtObject {
        property real scale: 1.0
        property int expressiveDefaultSpatial: 500 * scale
        property int expressiveEffects: 200 * scale
        property int expressiveFastSpatial: 350 * scale
        property int extraLarge: 1000 * scale
        property int large: 600 * scale
        property int normal: 400 * scale
        property int small: 200 * scale
    }

    component AnimationsComponent: QtObject {
        readonly property AnimationCurvesComponent curves: AnimationCurvesComponent {}
        readonly property AnimationDurationsComponent durations: AnimationDurationsComponent {}
    }

    component RoundingComponent: QtObject {
        property real scale: 1
        property int small: 12 * scale
        property int normal: 17 * scale
        property int large: 25 * scale
        property int full: 1000 * scale
    }

    component SpacingComponent: QtObject {
        property real scale: 1
        property int small: 7 * scale
        property int smaller: 10 * scale
        property int normal: 12 * scale
        property int larger: 15 * scale
        property int large: 20 * scale
    }

    component PaddingComponent: QtObject {
        property real scale: 1
        property int small: 5 * scale
        property int smaller: 7 * scale
        property int normal: 10 * scale
        property int larger: 12 * scale
        property int large: 15 * scale
    }

    readonly property ColorsComponent colors: ColorsComponent {}
    readonly property FontsComponent fonts: FontsComponent {}
    readonly property AnimationsComponent animations: AnimationsComponent {}
    readonly property RoundingComponent rounding: RoundingComponent {}
    readonly property SpacingComponent spacing: SpacingComponent {}
    readonly property PaddingComponent padding: PaddingComponent {}
}
