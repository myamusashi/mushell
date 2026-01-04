pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

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
        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
        radius: root.hasNotifications ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        radius: root.hasNotifications ? 40 : 0
        color: GlobalStates.drawerColors
    }

    WrapperRectangle {
        anchors.fill: parent
        margin: Appearance.margin.normal
        color: GlobalStates.drawerColors
        radius: 0
        bottomLeftRadius: Appearance.rounding.normal

        ListView {
            id: notifListView

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

                isPopup: true
                notif: modelData
                onEntered: modelData.timer?.stop()
                onExited: modelData.timer?.restart()
            }
        }
    }
}
