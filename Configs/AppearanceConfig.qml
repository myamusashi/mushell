import Quickshell.Io

JsonObject {
    id: root

	property AnimationsComponent animations: AnimationsComponent {}
    property FontsComponent fonts: FontsComponent {}
	property MarginComponent margin: MarginComponent {}
	property PaddingComponent padding: PaddingComponent {}
    property RoundingComponent rounding: RoundingComponent {}
    property SpacingComponent spacing: SpacingComponent {}

    component FontFamily: JsonObject {
        property string material: "Material Symbols Rounded"
        property string mono: "Hack"
        property string sans: "Google Sans Flex"
    }

    component FontSize: JsonObject {
        property int scale: 1
        property int small: 12 * scale
        property int medium: 13 * scale
        property int normal: 14 * scale
        property int large: 16 * scale
        property int larger: 18 * scale
        property int extraLarge: 30 * scale
    }

    component FontsComponent: JsonObject {
        property FontFamily family: FontFamily {}
        property FontSize size: FontSize {}
    }

    component AnimationCurvesComponent: JsonObject {
        property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    }

    component AnimationDurationsComponent: JsonObject {
        property int scale: 1
        property int emphasized: 500 * scale
        property int emphasizedAccel: 200 * scale
        property int emphasizedDecel: 400 * scale
        property int expressiveDefaultSpatial: 500 * scale
        property int expressiveEffects: 200 * scale
        property int expressiveFastSpatial: 350 * scale
        property int extraLarge: 1000 * scale
        property int large: 600 * scale
        property int normal: 300 * scale
        property int small: 200 * scale
    }

    component AnimationsComponent: JsonObject {
        property AnimationCurvesComponent curves: AnimationCurvesComponent {}
        property AnimationDurationsComponent durations: AnimationDurationsComponent {}
    }

    component RoundingComponent: JsonObject {
        property int small: 12
        property int normal: 17
        property int large: 25
        property int full: 1000
    }

    component SpacingComponent: JsonObject {
        property int small: 7
        property int smaller: 10
        property int normal: 12
        property int larger: 15
        property int large: 20
    }

    component PaddingComponent: JsonObject {
        property int small: 5
        property int smaller: 7
        property int normal: 10
        property int larger: 12
        property int large: 15
    }

    component MarginComponent: JsonObject {
        property int small: 5
        property int smaller: 7
        property int normal: 10
        property int larger: 12
        property int large: 15
    }
}
