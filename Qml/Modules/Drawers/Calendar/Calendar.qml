pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Item {
    id: container

    anchors {
        top: parent.top
        right: parent.right
        rightMargin: Configs.generals.outerBorderSize
    }

    readonly property bool isCalendarShow: GlobalStates.isCalendarOpen
    property real cellWidth: (width - Appearance.margin.normal * 2) / 7

    implicitWidth: parent.width * 0.2
    implicitHeight: isCalendarShow ? 300 : 0
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
        active: GlobalStates.isCalendarOpen
    }

    WrapperRectangle {
        anchors.fill: parent
        margin: Appearance.margin.normal
        color: GlobalStates.drawerColors
        radius: 0
        bottomLeftRadius: Appearance.rounding.large

        Loader {
            id: contentLoader

            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && container.isCalendarShow // qmllint disable
            asynchronous: true
            sourceComponent: Content {}
        }
    }
}
