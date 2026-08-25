import QtQuick
import QtQuick.Effects

import qs.Services

// credit: https://github.com/caelestia-dots/shell/blob/main/components/effects/Elevation.qml
RectangularShadow {
    id: root

    anchors.fill: parent

    property int level
    property real elevationDp: [0, 1, 3, 6, 8, 12][level]

    color: Qt.alpha(Colours.m3Colors.m3Shadow, 0.7)
    blur: (elevationDp * 5) ** 0.7
    spread: -elevationDp * 0.3 + (elevationDp * 0.1) ** 2
    offset.y: elevationDp / 2

    Behavior on elevationDp {
        NAnim {}
    }
}
