pragma ComponentBehavior: Bound

import QtQuick

import Quickshell

import qs.Components
import qs.Configs
import qs.Services

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
    height: hasNotifications ? Math.min(notifListView.contentHeight + 30, parent.height * 0.5) : 0
    color: Colours.m3Colors.m3Background
    radius: 0
    bottomLeftRadius: Appearance.rounding.normal

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    ListView {
        id: notifListView

        anchors.fill: container
        spacing: Appearance.spacing.normal
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        model: ScriptModel {
            values: [...Notifs.popups]
        }

        cacheBuffer: 200
        reuseItems: true

        delegate: Wrapper {
            required property var modelData
            required property int index

            notif: modelData
            width: notifListView.width

            onEntered: {
                modelData.timer.stop();
            }
            onExited: {
                modelData.timer.restart();
            }
        }
    }
}
