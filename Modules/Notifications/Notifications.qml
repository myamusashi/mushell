pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Configs
import qs.Services
import qs.Components

import "Components"

StyledRect {
    id: container

    anchors {
        right: parent.right
        top: parent.top
        rightMargin: 5
        topMargin: 5
    }

    property bool hasNotifications: Notifs.popups.length > 0

    width: Hypr.focusedMonitor.width * 0.2
    height: hasNotifications ? Math.min(notifColumn.height + 30, parent.height * 0.5) : 0
    color: Themes.m3Colors.m3Background
    radius: 0
    bottomLeftRadius: Appearance.rounding.normal

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Flickable {
        id: notifFlickable

        anchors.fill: container
        contentHeight: notifColumn.height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: notifColumn

            width: parent.width
            spacing: Appearance.spacing.normal

            Repeater {
                model: ScriptModel {
                    values: [...Notifs.popups]
                }

                delegate: Wrapper {
                    required property var modelData
                    notif: modelData
                    width: notifColumn.width

                    onEntered: {
                        modelData.timer.stop();
                    }
                    onExited: {
                        modelData.timer.restart();
                    }
                }
            }
        }
    }
}
