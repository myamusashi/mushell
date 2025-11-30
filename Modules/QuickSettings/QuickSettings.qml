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

    function toggleControlCenter(): void {
        isControlCenterOpen = !isControlCenterOpen;
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

    OuterShapeItem {
        id: root

        content: container

        ColumnLayout {
            id: container

            width: Hypr.focusedMonitor.width * 0.3
            height: scope.isControlCenterOpen ? contentHeight : 0
            spacing: 0

            // Calculate total content height
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

            clip: true // Important for smooth reveal

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

                    Shape {
                        id: shapeRect
                        anchors.fill: parent

                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: Themes.m3Colors.m3Surface

                            startX: topLeftRadius
                            startY: 0

                            // Top edge
                            PathLine {
                                x: shapeRect.width - topRightRadius
                                y: 0
                            }

                            // Top-right corner
                            PathArc {
                                x: shapeRect.width
                                y: topRightRadius
                                radiusX: topRightRadius
                                radiusY: topRightRadius
                                direction: PathArc.Clockwise
                            }

                            // Right edge
                            PathLine {
                                x: shapeRect.width
                                y: shapeRect.height - bottomRightRadius
                            }

                            // Bottom-right corner
                            PathArc {
                                x: shapeRect.width - bottomRightRadius
                                y: shapeRect.height
                                radiusX: bottomRightRadius
                                radiusY: bottomRightRadius
                                direction: PathArc.Clockwise
                            }

                            // Bottom edge
                            PathLine {
                                x: bottomLeftRadius
                                y: shapeRect.height
                            }

                            // Bottom-left corner
                            PathArc {
                                x: 0
                                y: shapeRect.height - bottomLeftRadius
                                radiusX: bottomLeftRadius
                                radiusY: bottomLeftRadius
                                direction: PathArc.Clockwise
                            }

                            // Left edge
                            PathLine {
                                x: 0
                                y: topLeftRadius
                            }

                            // Top-left corner
                            PathArc {
                                x: topLeftRadius
                                y: 0
                                radiusX: topLeftRadius
                                radiusY: topLeftRadius
                                direction: PathArc.Clockwise
                            }
                        }

                        property int viewIndex: 0
                        property real topLeftRadius: 0
                        property real topRightRadius: 0
                        property real bottomLeftRadius: Appearance.rounding.normal
                        property real bottomRightRadius: Appearance.rounding.normal

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

    IpcHandler {
        target: "controlCenter"
        function toggle(): void {
            scope.toggleControlCenter();
        }
    }
}
