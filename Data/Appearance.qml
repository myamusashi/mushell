pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	component ColorsComponent: QtObject {
		readonly property color background: "#111418"
		readonly property color error: "#ffb4ab"
		readonly property color error_container: "#93000a"
		readonly property color inverse_on_surface: "#2e3135"
		readonly property color inverse_primary: "#37618e"
		readonly property color inverse_surface: "#e1e2e8"
		readonly property color on_background: "#e1e2e8"
		readonly property color on_error: "#690005"
		readonly property color on_error_container: "#ffdad6"
		readonly property color on_primary: "#003259"
		readonly property color on_primary_container: "#d2e4ff"
		readonly property color on_primary_fixed: "#001c37"
		readonly property color on_primary_fixed_variant: "#1b4975"
		readonly property color on_secondary: "#253141"
		readonly property color on_secondary_container: "#d7e3f8"
		readonly property color on_secondary_fixed: "#101c2b"
		readonly property color on_secondary_fixed_variant: "#3c4858"
		readonly property color on_surface: "#e1e2e8"
		readonly property color on_surface_variant: "#c3c6cf"
		readonly property color on_tertiary: "#3b2947"
		readonly property color on_tertiary_container: "#f3daff"
		readonly property color on_tertiary_fixed: "#251431"
		readonly property color on_tertiary_fixed_variant: "#533f5f"
		readonly property color outline: "#8d9199"
		readonly property color outline_variant: "#43474e"
		readonly property color primary: "#a1c9fd"
		readonly property color primary_container: "#1b4975"
		readonly property color primary_fixed: "#d2e4ff"
		readonly property color primary_fixed_dim: "#a1c9fd"
		readonly property color scrim: "#000000"
		readonly property color secondary: "#bbc7db"
		readonly property color secondary_container: "#3c4858"
		readonly property color secondary_fixed: "#d7e3f8"
		readonly property color secondary_fixed_dim: "#bbc7db"
		readonly property color shadow: "#000000"
		readonly property color surface: "#111418"
		readonly property color surface_bright: "#36393e"
		readonly property color surface_container: "#1d2024"
		readonly property color surface_container_high: "#272a2f"
		readonly property color surface_container_highest: "#32353a"
		readonly property color surface_container_low: "#191c20"
		readonly property color surface_container_lowest: "#0b0e13"
		readonly property color surface_dim: "#111418"
		readonly property color surface_tint: "#a1c9fd"
		readonly property color surface_variant: "#43474e"
		readonly property color tertiary: "#d7bee4"
		readonly property color tertiary_container: "#533f5f"
		readonly property color tertiary_fixed: "#f3daff"
		readonly property color tertiary_fixed_dim: "#d7bee4"

		function withAlpha(color, alpha) {
			return Qt.rgba(color.r, color.g, color.b, alpha);
		}
	}

	component FontsComponent: QtObject {
		readonly property string family_Material: "Material Symbols Rounded"
		readonly property string family_Mono: "Liga SFMono Nerd Font"
		readonly property string family_Sans: "SF Pro Display"

		readonly property real small: 12
		readonly property real medium: 13
		readonly property real normal: 14
		readonly property real large: 16
		readonly property real larger: 18
		readonly property real extraLarge: 30
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
		property int expressiveDefaultSpatial: 500
		property int expressiveEffects: 200
		property int expressiveFastSpatial: 350
		property int extraLarge: 1000
		property int large: 600
		property int normal: 400
		property int small: 200
	}

	component AnimationsComponent: QtObject {
		readonly property AnimationCurvesComponent curves: AnimationCurvesComponent {}
		readonly property AnimationDurationsComponent durations: AnimationDurationsComponent {}
	}

	component RoundingComponent: QtObject {
		property int small: 12
		property int normal: 17
		property int large: 25
		property int full: 1000
	}

	component SpacingComponent: QtObject {
		property int small: 7
		property int smaller: 10
		property int normal: 12
		property int larger: 15
		property int large: 20
	}

	component PaddingComponent: QtObject {
		property int small: 5
		property int smaller: 7
		property int normal: 10
		property int larger: 12
		property int large: 15
	}

	component MarginComponent: QtObject {
		property int small: 5
		property int smaller: 7
		property int normal: 10
		property int larger: 12
		property int large: 15
	}

	readonly property ColorsComponent colors: ColorsComponent {}
	readonly property FontsComponent fonts: FontsComponent {}
	readonly property AnimationsComponent animations: AnimationsComponent {}
	readonly property RoundingComponent rounding: RoundingComponent {}
	readonly property SpacingComponent spacing: SpacingComponent {}
	readonly property PaddingComponent padding: PaddingComponent {}
	readonly property MarginComponent margin: MarginComponent {}
}
