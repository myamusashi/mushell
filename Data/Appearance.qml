pragma Singleton

import Quickshell
import QtQuick

// Yoink this from Caelestia
Singleton {
    id: root

    component FontsComponent: QtObject {
        readonly property string family_Material: "Material Symbols Rounded"
        readonly property string family_Mono: "SFMono Nerd Font"
        readonly property string family_Sans: "SF Pro"

        readonly property real small: 12
        readonly property real medium: 13
        readonly property real normal: 14
        readonly property real large: 16
        readonly property real larger: 18
        readonly property real extraLarge: 30
    }

    component AnimationCurvesComponent: QtObject {
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1
            / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
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

    readonly property FontsComponent fonts: FontsComponent {}
    readonly property AnimationsComponent animations: AnimationsComponent {}
    readonly property RoundingComponent rounding: RoundingComponent {}
    readonly property SpacingComponent spacing: SpacingComponent {}
    readonly property PaddingComponent padding: PaddingComponent {}
    readonly property MarginComponent margin: MarginComponent {}
}
