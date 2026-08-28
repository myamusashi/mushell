pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire

import qs.Components.Base
import qs.Core.Configs

Item {
    id: root

    required property var controller
    required property PwNodeLinkTracker linkTracker

    readonly property real perAppWidth: repeater.count * controller.itemSize + Math.max(0, repeater.count - 1) * controller.itemSpacing

    anchors.fill: parent

    Row {
        id: perAppContainer

        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }

        width: root.controller.openPerAppVolume ? root.perAppWidth : 0
        height: mainVolumeControl.height
        spacing: root.controller.itemSpacing
        clip: true

        Behavior on width {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Repeater {
            id: repeater

            model: root.linkTracker.linkGroups
            delegate: Mixer {
                required property PwLinkGroup modelData

                width: root.controller.itemSize
                height: perAppContainer.height
                audioNode: modelData.source
                sliderHeight: root.controller.sliderHeight
                itemSize: root.controller.itemSize
            }
        }
    }

    MasterControl {
        id: mainVolumeControl

        anchors {
            right: parent.right
            rightMargin: 5
            verticalCenter: parent.verticalCenter
        }

        sliderHeight: root.controller.sliderHeight
        controller: root.controller
    }
}
