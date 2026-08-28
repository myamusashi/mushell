pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Item {
    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
        rightMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
    }

    implicitWidth: GlobalStates.isOSDVisible("volume") ? wrapper.implicitWidth : 0
    implicitHeight: 280
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.TopRightCorner
        location2: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        active: GlobalStates.isOSDVisible("volume")
    }

    WrapperRectangle {
        id: wrapper

        anchors.fill: parent
        implicitWidth: 60 + (Volume.openPerAppVolume && loader.item ? loader.item.perAppWidth + Volume.itemSpacing : 0) // qmllint disable
        color: GlobalStates.drawerColors
        clip: true
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        bottomLeftRadius: topLeftRadius

        Loader {
            id: loader

            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isOSDVisible("volume") // qmllint disable
            asynchronous: true
            onActiveChanged: {
                if (!active)
                    Volume.openPerAppVolume = false;
            }

            sourceComponent: Content {
                controller: Volume
                linkTracker: Volume.linkTracker
            }
        }
    }
}
