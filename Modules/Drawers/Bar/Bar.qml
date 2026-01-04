import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    implicitWidth: Configs.bar.compact ? parent.width * 0.6 : parent.width
    implicitHeight: window.modelData.name === Hypr.focusedMonitor.name ? GlobalStates.isBarOpen ? 40 : 0 : 0

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    IpcHandler {
        target: "layershell"

        function open(): void {
            GlobalStates.isBarOpen = true;
        }
        function close(): void {
            GlobalStates.isBarOpen = false;
        }
        function toggle(): void {
            GlobalStates.isBarOpen = !GlobalStates.isBarOpen;
        }
    }

    GlobalShortcut {
        name: "layershell"
        onPressed: GlobalStates.isBarOpen = !GlobalStates.isBarOpen
    }

    Corner {
        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
        radius: Configs.bar.compact ? GlobalStates.isBarOpen ? 20 : 0 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.TopRightCorner
        extensionSide: Qt.Horizontal
        radius: Configs.bar.compact ? GlobalStates.isBarOpen ? 20 : 0 : 0
        color: GlobalStates.drawerColors
    }

    StyledRect {
        anchors.fill: parent
        color: GlobalStates.drawerColors
        radius: 0
        bottomLeftRadius: Configs.bar.compact ? Appearance.rounding.large : 0
        bottomRightRadius: Configs.bar.compact ? bottomLeftRadius : 0
        clip: true
        Loader {
            anchors.fill: parent
            active: window.modelData.name === Hypr.focusedMonitor.name && GlobalStates.isBarOpen
            asynchronous: true
            sourceComponent: Item {
                anchors {
                    fill: parent
                    leftMargin: 5
                    rightMargin: 5
                }

                Left {
                    implicitHeight: parent.height
                    implicitWidth: parent.width / 6
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                }
                Middle {
                    implicitHeight: parent.height
                    implicitWidth: parent.width / 6
                    anchors.centerIn: parent
                }
                Right {
                    implicitHeight: parent.height
                    implicitWidth: parent.width / 6
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
