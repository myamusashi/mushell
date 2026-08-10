pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Menu

Popup {
    id: root

    default property alias items: menuSurface.content

    padding: 0
    background: null
    focus: true
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
    transformOrigin: Popup.Center

    MenuSurface {
        id: menuSurface

        anchors.fill: parent
        implicitWidth: 220
    }

    function openAt(x: real, y: real) {
        root.x = x;
        root.y = y;
        root.open();
    }

    enter: Transition {
        ParallelAnimation {
            NAnim {
                property: "opacity"
                from: 0.0
                to: 1.0
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
            NAnim {
                property: "scale"
                from: 0.8
                to: 1.0
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NAnim {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
            NAnim {
                property: "scale"
                from: 1.0
                to: 0.8
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
        }
    }
}
