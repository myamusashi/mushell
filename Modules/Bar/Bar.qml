import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Components

StyledRect {
	color: Themes.m3Colors.m3Background
	height: GlobalStates.isBarOpen ? 40 : 5
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

    RowLayout {
        id: rowbar

		visible: GlobalStates.isBarOpen
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
            Layout.alignment: Qt.AlignCenter
        }
        Right {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width / 6
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
    }
}
