import QtQuick
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

WrapperItem {
    implicitWidth: Configs.bar.compact ? parent.width * 0.6 : parent.width
    implicitHeight: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isBarOpen ? 40 : 0 // qmllint disable

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    WrapperRectangle {
        radius: 0
        bottomLeftRadius: Configs.bar.compact ? Appearance.rounding.large : 0
        bottomRightRadius: Configs.bar.compact ? bottomLeftRadius : 0
        color: "transparent"

        Loader {
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isBarOpen // qmllint disable
            asynchronous: false
            sourceComponent: Item {
                anchors {
                    fill: parent
                    leftMargin: 5
                    rightMargin: 5
                }

                Left {
                    implicitHeight: parent.height
                    implicitWidth: parent.width / 6
                    monitor: window.modelData // qmllint disable
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                }
                Middle {
                    implicitHeight: parent.height
                    implicitWidth: parent.width / 6
                    anchors.centerIn: parent
                }
                Right {
                    implicitHeight: parent.height
                    implicitWidth: parent.width / 6
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
