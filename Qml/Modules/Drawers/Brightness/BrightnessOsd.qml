pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    anchors {
        horizontalCenter: parent.horizontalCenter
        bottom: parent.bottom
        bottomMargin: 50
    }

    readonly property int pillWidth: 260
    readonly property int pillHeight: 104
    readonly property bool shouldShow: Brightness.available && GlobalStates.isOSDVisible("brightness")
    readonly property bool onFocusedMonitor: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    property bool primed: false

    implicitWidth: shouldShow && onFocusedMonitor ? pillWidth : 0
    implicitHeight: pillHeight

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Connections {
        target: Brightness

        function onValueChanged() {
            if (!Brightness.available)
                return;
            if (!root.primed) {
                root.primed = true;
                return;
            }
            GlobalStates.showOSD("brightness");
        }
    }

    Loader {
        anchors.fill: parent
        active: root.shouldShow && root.onFocusedMonitor
        asynchronous: true

        sourceComponent: StyledRect {
            id: pill

            readonly property real levelRatio: Brightness.value / (Brightness.maxValue || 1)

            anchors.fill: parent
            radius: Appearance.rounding.small
            color: GlobalStates.drawerColors
            clip: true

            property bool showLevel: false

            Timer {
                id: levelHideTimer

                interval: 500
                onTriggered: pill.showLevel = false
            }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        GlobalStates.pauseOSD("brightness");
                    else
                        GlobalStates.resumeOSD("brightness");
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                Item {
                    id: levelDisplay

                    implicitWidth: 48
                    implicitHeight: 48
                    anchors.horizontalCenter: parent.horizontalCenter

                    Item {
                        id: iconSwap

                        anchors.fill: parent

                        opacity: pill.showLevel ? 0 : 1
                        scale: pill.showLevel ? 0.5 : 1

                        Behavior on opacity {
                            NAnim {
                                duration: Appearance.animations.durations.expressiveDefaultSpatial
                                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                            }
                        }
                        Behavior on scale {
                            NAnim {
                                duration: Appearance.animations.durations.expressiveDefaultSpatial
                                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                            }
                        }

                        Icon {
                            id: brightnessIcon

                            anchors.centerIn: parent
                            type: Icon.Material
                            icon: "brightness_5"
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge * 1.4

                            // Lower brightness -> darker icon
                            opacity: 0.25 + 0.75 * pill.levelRatio

                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.normal
                                }
                            }
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: Brightness.value.toFixed(0)
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.extraLarge * 0.8
                        font.weight: Font.DemiBold
                        opacity: pill.showLevel ? 1 : 0
                        scale: pill.showLevel ? 1 : 0.5

                        Behavior on opacity {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }
                        Behavior on scale {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }
                    }
                }

                SegmentBar {
                    anchors.horizontalCenter: parent.horizontalCenter

                    onInteractStarted: {
                        GlobalStates.pauseOSD("brightness");
                        levelHideTimer.stop();
                        pill.showLevel = true;
                    }
                    onInteractEnded: {
                        GlobalStates.resumeOSD("brightness");
                        levelHideTimer.restart();
                    }
                }
            }
        }
    }
}
