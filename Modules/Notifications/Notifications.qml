pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components
import qs.Configs
import qs.Services

import "Components"

Item {
    id: root

    property bool hasNotifications: Notifs.popups.length > 0

    implicitWidth: parent.width * 0.2
    implicitHeight: hasNotifications ? Math.min(notifListView.contentHeight + 30, parent.height * 0.5) : 0
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        right: parent.right
        top: parent.top
    }

    Corner {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: -radius
        radius: root.hasNotifications ? 40 : 0
        corner: 2
        bgColor: Colours.m3Colors.m3Surface

        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    Corner {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: -radius
        radius: root.hasNotifications ? 40 : 0
        corner: 2
        bgColor: Colours.m3Colors.m3Surface

        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Colours.m3Colors.m3Background
        radius: 0
        bottomLeftRadius: Appearance.rounding.normal

        ListView {
            id: notifListView

            anchors.fill: parent
            spacing: Appearance.spacing.normal
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            model: ScriptModel {
                values: [...Notifs.popups]
            }

            cacheBuffer: 200

            delegate: Wrapper {
                required property var modelData
                required property int index

                notif: modelData
                onEntered: modelData.timer?.stop()
                onExited: modelData.timer?.restart()
            }
        }
    }
}
