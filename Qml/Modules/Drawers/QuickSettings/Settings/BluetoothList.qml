pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "Bluetooth" as BT

import qs.Components.Base
import qs.Core.Configs
import qs.Services

WrapperRectangle {
    id: root

    property bool isVisible: false
    property real zoomOriginX: parent.width / 2
    property real zoomOriginY: parent.height / 2

    clip: true

    border {
        width: 1
        color: Colours.m3Colors.m3Outline
    }
    implicitWidth: parent.width * 0.8
    implicitHeight: Math.min(loader.implicitHeight + 20 * 2, parent.height * 0.8)
    margin: Appearance.margin.normal
    radius: Appearance.rounding.small
    color: Colours.m3Colors.m3SurfaceContainer
    scale: isVisible ? 1.0 : 0.5
    opacity: isVisible ? 1.0 : 0.0
    transformOrigin: Item.Center

    transform: Translate {
        x: root.isVisible ? 0 : root.zoomOriginX - root.width / 2
        y: root.isVisible ? 0 : root.zoomOriginY - root.height / 2

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on y {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Flickable {
        id: flick

        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        contentHeight: loader.implicitHeight
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        Loader {
            id: loader

            width: parent.width
            active: root.isVisible
            asynchronous: true
            sourceComponent: ColumnLayout {
                width: loader.width
                spacing: Appearance.spacing.small

                BT.Header {}

                BT.AdapterControls {
                    isVisible: root.isVisible
                }

                BT.PairedDevices {}

                BT.AvailableDevices {}

                BT.BlockedDevices {}
            }
        }
    }
}
