pragma ComponentBehavior: Bound

import QtQuick

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    implicitWidth: parent.width * 0.15
    implicitHeight: calculateHeight()
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
    }

    function calculateHeight() {
        var totalHeight = 0;
        var spacing = 10;
        var padding = 10;

        if (GlobalStates.isOSDVisible("capslock"))
            totalHeight += 50;
        if (GlobalStates.isOSDVisible("numlock"))
            totalHeight += 50;
        if (GlobalStates.isOSDVisible("volume"))
            totalHeight += 80;

        var activeCount = 0;
        if (GlobalStates.isOSDVisible("volume"))
            activeCount++;
        if (GlobalStates.isOSDVisible("capslock"))
            activeCount++;
        if (GlobalStates.isOSDVisible("numlock"))
            activeCount++;

        if (activeCount > 1)
            totalHeight += (activeCount - 1) * spacing;

        return totalHeight > 0 ? totalHeight + (padding * 2) : 0;
    }

    Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Horizontal
        radius: (GlobalStates.isOSDVisible("volume") || GlobalStates.isOSDVisible("numlock") || GlobalStates.isOSDVisible("capslock")) ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomLeftCorner
        extensionSide: Qt.Horizontal
        radius: (GlobalStates.isOSDVisible("volume") || GlobalStates.isOSDVisible("numlock") || GlobalStates.isOSDVisible("capslock")) ? 40 : 0
        color: GlobalStates.drawerColors
    }

    StyledRect {
        anchors.fill: parent
        radius: 0
        clip: true
        topLeftRadius: Appearance.rounding.large
        topRightRadius: topLeftRadius
        color: GlobalStates.drawerColors

        Loader {
            anchors.fill: parent
            active: window.modelData.name === Hypr.focusedMonitor.name && (GlobalStates.isOSDVisible("volume") || GlobalStates.isOSDVisible("numlock") || GlobalStates.isOSDVisible("capslock"))
            asynchronous: true

            sourceComponent: Column {
                anchors {
                    fill: parent
                    margins: 15
                }
                spacing: Appearance.spacing.normal

                CapsLockWidget {}
                NumLockWidget {}
                Volumes {}
            }
        }
    }
}
