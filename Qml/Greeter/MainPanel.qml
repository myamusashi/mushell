pragma ComponentBehavior: Bound

import QtQuick

import Quickshell

import qs.Components.Base
import qs.Components.Feedback
import qs.Core.Configs
import qs.Services

PanelWindow {
    id: root

    required property Auth auth
    property bool launching: false

    signal entranceFinished
    signal logoutRequested

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    color: "transparent"
    focusable: true

    GreeterUi {
        id: ui

        anchors.fill: parent
        auth: root.auth
        visible: !root.launching

        onEntranceFinished: root.entranceFinished()
        onLogoutRequested: root.logoutRequested()
    }

    Item {
        id: loadingOverlay

        anchors.fill: parent
        opacity: root.launching ? 1 : 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        LoadingIndicator {
            anchors.centerIn: parent
            status: root.launching
            width: 64
            height: 64
            radius: 32
            padding: 30
        }

        StyledText {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.verticalCenter
                topMargin: 72
            }
            text: "Starting session…"
            color: Colours.m3Colors.m3OnBackground
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
        }
    }
}
