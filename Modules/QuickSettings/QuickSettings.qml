pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Services
import qs.Components

import "Settings"

Scope {
    id: scope

    property bool isControlCenterOpen: false
    property int state: 0
    property bool triggerAnimation: false
    property bool shouldDestroy: false

    function toggleControlCenter(): void {
        isControlCenterOpen = !isControlCenterOpen;
    }

    onIsControlCenterOpenChanged: {
        if (isControlCenterOpen) {
            shouldDestroy = false;
            triggerAnimation = false;
            animationTriggerTimer.restart();
        } else {
            triggerAnimation = false;
            destroyTimer.restart();
        }
    }

    Timer {
        id: animationTriggerTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (scope.isControlCenterOpen) {
                scope.triggerAnimation = true;
            }
        }
    }

    Timer {
        id: destroyTimer
        interval: Appearance.animations.durations.small + 50
        repeat: false
        onTriggered: {
            scope.shouldDestroy = true;
        }
    }

    GlobalShortcut {
        name: "ControlCenter"
        onPressed: scope.toggleControlCenter()
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: gc()
    }

    LazyLoader {
        loading: scope.isControlCenterOpen
        activeAsync: scope.isControlCenterOpen || !scope.shouldDestroy

        component: OuterShapeItem {
            id: root

            content: container

            ColumnLayout {
                id: container

                width: Hypr.focusedMonitor.width * 0.3
                height: scope.triggerAnimation ? contentHeight : 0
                spacing: 0

                property real contentHeight: tabBar.implicitHeight + divider.implicitHeight + 500

                Behavior on height {
                    NAnim {
                        duration: Appearance.animations.durations.small
                        easing.type: Easing.OutCubic
                    }
                }

                anchors {
                    top: parent.top
                    right: parent.right
                    rightMargin: 60
                }

                clip: true

                TabRows {
                    id: tabBar

                    state: scope.state
                    scaleFactor: Math.min(1.0, container.width / container.width)
                    visible: scope.isControlCenterOpen
                    topLeftRadius: 0
                    topRightRadius: 0

                    Layout.fillWidth: true

                    onTabClicked: index => {
                        scope.state = index;
                        controlCenterStackView.currentItem.viewIndex = index;
                    }
                }

                StyledRect {
                    id: divider

                    Layout.fillWidth: true
                    implicitHeight: scope.isControlCenterOpen ? 1 : 0
                    visible: scope.isControlCenterOpen
                    color: Themes.m3Colors.m3OutlineVariant

                    Behavior on implicitHeight {
                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }
                }

                StackView {
                    id: controlCenterStackView

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 500

                    property Component viewComponent: contentView

                    initialItem: viewComponent

                    onCurrentItemChanged: {
                        if (currentItem)
                            currentItem.viewIndex = scope.state;
                    }

                    Component {
                        id: contentView

                        StyledRect {
							id: shapeRect

                            anchors.fill: parent

							radius: 0
							bottomLeftRadius: Appearance.rounding.normal
                            bottomRightRadius: Appearance.rounding.normal
							color: Themes.m3Colors.m3Background

							property int viewIndex: 0

                            Loader {
                                anchors.fill: parent
                                active: parent.viewIndex === 0
                                asynchronous: true
                                visible: active

                                sourceComponent: Settings {}
                            }

                            Loader {
                                anchors.fill: parent
                                active: parent.viewIndex === 1
                                asynchronous: true
                                visible: active

                                sourceComponent: VolumeSettings {}
                            }

                            Loader {
                                anchors.fill: parent
                                active: parent.viewIndex === 2
                                asynchronous: true
                                visible: active

                                sourceComponent: Performances {}
                            }

                            Loader {
                                anchors.fill: parent
                                active: parent.viewIndex === 3
                                asynchronous: true
                                visible: active

                                sourceComponent: Weathers {}
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "controlCenter"
        function toggle(): void {
            scope.toggleControlCenter();
        }
    }
}
