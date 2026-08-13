pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Components.Base
import qs.Core.Utils
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property Auth auth
    property bool playEntrance: true

    signal entranceFinished
    signal logoutRequested

    Column {
        id: clockColumn

        anchors {
            top: parent.top
            topMargin: Appearance.margin.large * 4
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Appearance.spacing.smaller

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(Time.date, "HH:mm")
            color: Colours.m3Colors.m3OnBackground
            font.pixelSize: 72
            font.weight: Font.Medium
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(Time.date, "dddd, d MMMM")
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
        }
    }

    UserCard {
        id: userCard

        anchors.centerIn: parent
        auth: root.auth
        opacity: root.playEntrance ? 0 : 1
        scale: root.playEntrance ? 0.9 : 1
    }

    Item {
        id: powerControls

        anchors {
            bottom: parent.bottom
            bottomMargin: Appearance.margin.large * 2
            right: parent.right
            rightMargin: Appearance.margin.large * 2
        }
        implicitWidth: powerRow.implicitWidth
        implicitHeight: powerRow.implicitHeight
        opacity: root.playEntrance ? 0 : 1

        RowLayout {
            id: powerRow

            spacing: Appearance.spacing.small

            StyledButton {
                icon.name: "logout"
                icon.color: Colours.m3Colors.m3OnSurface
                color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHighest, 0.8)
                leftPad: 12
                rightPad: 12

                onClicked: root.logoutRequested()
            }

            StyledButton {
                icon.name: "restart_alt"
                icon.color: Colours.m3Colors.m3OnSurface
                color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHighest, 0.8)
                leftPad: 12
                rightPad: 12

                onClicked: Quickshell.execDetached({
                    command: ["systemctl", "reboot"]
                })
            }

            StyledButton {
                icon.name: "power_settings_new"
                icon.color: Colours.m3Colors.m3OnSurface
                color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHighest, 0.8)
                leftPad: 12
                rightPad: 12

                onClicked: Quickshell.execDetached({
                    command: ["systemctl", "poweroff"]
                })
            }
        }
    }

    Component.onCompleted: {
        if (root.playEntrance)
            entranceSequence.start();
    }

    SequentialAnimation {
        id: entranceSequence

        ParallelAnimation {
            NAnim {
                target: powerControls
                property: "opacity"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        PauseAnimation {
            duration: 150
        }

        ParallelAnimation {
            NAnim {
                target: userCard
                property: "opacity"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: userCard
                property: "scale"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        onStopped: root.entranceFinished()
    }
}
