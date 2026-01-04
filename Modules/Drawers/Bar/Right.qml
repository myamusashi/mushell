pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Widgets as Wid

RowLayout {
    anchors.margins: 5
    layoutDirection: Qt.RightToLeft
    spacing: Appearance.spacing.small

    clip: true
    Wid.Clock {}
    Wid.Tray {}
    ClippingRectangle {
        implicitWidth: quickSettingsLayout.childrenRect.width
        implicitHeight: parent.height * 0.7
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        Row {
            id: quickSettingsLayout

            anchors.fill: parent
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Appearance.spacing.normal

            Wid.Sound {
                implicitHeight: parent.height
            }

            Wid.Battery {
                implicitHeight: parent.height
                implicitWidth: 20
                widthBattery: 36
                heightBattery: 18
            }

            Wid.NotificationDots {
                implicitWidth: 50
                implicitHeight: parent.height
            }
        }

        MArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen
        }
    }
}
