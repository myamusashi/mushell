pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Item {
    id: root

    anchors {
        verticalCenter: parent.verticalCenter
        horizontalCenter: parent.horizontalCenter
    }

    implicitWidth: parent.width * 0.15
    implicitHeight: calculateHeight()
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    function calculateHeight() {
        var totalHeight = 0;
        var spacing = 10;
        var padding = 10;

        if (GlobalStates.isOSDVisible("capslock"))
            totalHeight += 50;
        if (GlobalStates.isOSDVisible("numlock"))
            totalHeight += 50;

        var activeCount = 0;
        if (GlobalStates.isOSDVisible("capslock"))
            activeCount++;
        if (GlobalStates.isOSDVisible("numlock"))
            activeCount++;

        if (activeCount > 1)
            totalHeight += (activeCount - 1) * spacing;

        return totalHeight > 0 ? totalHeight + (padding * 2) : 0;
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    StyledRect {
        anchors.fill: parent
        radius: Appearance.rounding.large
        clip: true
        color: GlobalStates.drawerColors

        Loader {
            anchors.fill: parent
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && (GlobalStates.isOSDVisible("numlock") || GlobalStates.isOSDVisible("capslock")) // qmllint disable
            asynchronous: true

            sourceComponent: Column {
                anchors {
                    fill: parent
                    margins: 15
                }
                spacing: Appearance.spacing.normal

                CapsLockWidget {}
                NumLockWidget {}
            }
        }
    }
}
