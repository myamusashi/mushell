pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Components.Base

import "Components"

Item {
    id: root

    anchors {
        right: parent.right
        top: parent.top
    }

    property bool hasNotifications: Notifs.popups.length > 0

    implicitWidth: Math.min(Math.round(parent.width * 0.22), 360)
    implicitHeight: hasNotifications ? Math.min(notifListView.contentHeight + 30, parent.height * 0.5) : 0
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.TopLeftCorner
        location2: Qt.BottomRightCorner
        extensionSide1: Qt.Horizontal
        extensionSide2: Qt.Vertical
        active: root.hasNotifications
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

            cacheBuffer: implicitHeight

            delegate: Wrapper {
                required property var modelData
                required property int index

                isPopup: true
                notif: modelData
            }
        }
    }
}
