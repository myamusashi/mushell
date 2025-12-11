import QtQuick
import QtQuick.Layouts

import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ClippingRectangle {
    color: Colours.m3Colors.m3Background
    height: GlobalStates.isBarOpen ? 40 : 10
    width: parent.width

    GlobalShortcut {
        name: "layershell"
        onPressed: GlobalStates.isBarOpen = !GlobalStates.isBarOpen
    }

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        anchors.fill: parent
        active: GlobalStates.isBarOpen
        asynchronous: true
        sourceComponent: RowLayout {
            id: rowbar

            anchors {
                fill: parent
                leftMargin: 5
                rightMargin: 5
            }

            Left {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width / 6
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Middle {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width / 6
            }
            Right {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width / 6
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
        }
    }
}
