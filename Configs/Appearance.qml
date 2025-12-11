pragma Singleton

import QtQuick
import Quickshell

// Yoink this from Caelestia
Singleton {
    id: root

    component FontsComponent: QtObject {
        readonly property string familyMaterial: "Material Symbols Rounded"
        readonly property string familyMono: "Hack"
        readonly property string familySans: "Google Sans Flex"
        readonly property int small: 12
        readonly property int medium: 13
        readonly property int normal: 14
        readonly property int large: 16
        readonly property int larger: 18
        readonly property int extraLarge: 30
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
        readonly property int emphasized: 500
        readonly property int emphasizedAccel: 200
        readonly property int emphasizedDecel: 400
        readonly property int expressiveDefaultSpatial: 500
        readonly property int expressiveEffects: 200
        readonly property int expressiveFastSpatial: 350
        readonly property int extraLarge: 1000
        readonly property int large: 600
        readonly property int normal: 300
        readonly property int small: 200
    }

    component AnimationsComponent: QtObject {
        readonly property AnimationCurvesComponent curves: AnimationCurvesComponent {}
        readonly property AnimationDurationsComponent durations: AnimationDurationsComponent {}
    }

    component RoundingComponent: QtObject {
        readonly property int small: 12
        readonly property int normal: 17
        readonly property int large: 25
        readonly property int full: 1000
    }

    component SpacingComponent: QtObject {
        readonly property int small: 7
        readonly property int smaller: 10
        readonly property int normal: 12
        readonly property int larger: 15
        readonly property int large: 20
    }

    component PaddingComponent: QtObject {
        readonly property int small: 5
        readonly property int smaller: 7
        readonly property int normal: 10
        readonly property int larger: 12
        readonly property int large: 15
    }

    component MarginComponent: QtObject {
        readonly property int small: 5
        readonly property int smaller: 7
        readonly property int normal: 10
        readonly property int larger: 12
        readonly property int large: 15
    }

    readonly property FontsComponent fonts: FontsComponent {}
    readonly property AnimationsComponent animations: AnimationsComponent {}
    readonly property RoundingComponent rounding: RoundingComponent {}
    readonly property SpacingComponent spacing: SpacingComponent {}
    readonly property PaddingComponent padding: PaddingComponent {}
    readonly property MarginComponent margin: MarginComponent {}
}
