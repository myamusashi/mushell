// Thx Rexiel for your Bar PR on quickshell-mirror
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland

import qs.Configs
import qs.Components

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: window

        property color barColor: Themes.m3Colors.m3Background

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {
            item: cornersArea
            intersection: Intersection.Subtract
        }

        visible: scope.isBarOpen

        anchors {
            left: true
            top: true
            right: true
            bottom: true
        }

        Scope {
            Exclusion {
                name: "left"
                exclusiveZone: leftBar.implicitWidth
                anchors.left: true
            }
            Exclusion {
                name: "top"
                exclusiveZone: topBar.implicitHeight
                anchors.top: true
            }
            Exclusion {
                name: "right"
                exclusiveZone: rightBar.implicitWidth
                anchors.right: true
            }
            Exclusion {
                name: "bottom"
                exclusiveZone: bottomBar.implicitHeight
                anchors.bottom: true
            }
        }

        Rectangle {
            id: leftBar

            implicitWidth: 5
            implicitHeight: QsWindow.window?.height ?? 0
            color: window.barColor
            anchors.left: parent.left
        }
        Rectangle {
            id: topBar

            implicitWidth: QsWindow.window?.width ?? 0
            implicitHeight: 40
            color: window.barColor
            anchors.top: parent.top

            Item {
                anchors.fill: parent

                RowLayout {
                    width: parent.width
                    anchors {
                        leftMargin: 5
                        rightMargin: 5
                    }
                    anchors.fill: parent
                    Left {
                        Layout.fillHeight: true
                        Layout.preferredWidth: parent.width / 6
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    }
                    Middle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: parent.width / 6
                        Layout.alignment: Qt.AlignCenter
                    }
                    Right {
                        Layout.fillHeight: true
                        Layout.preferredWidth: parent.width / 6
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    }
                }
            }
        }
        Rectangle {
            id: rightBar

            implicitWidth: 5
            implicitHeight: QsWindow.window?.height ?? 0
            color: window.barColor
            anchors.right: parent.right
        }
        Rectangle {
            id: bottomBar

            implicitWidth: QsWindow.window?.width ?? 0
            implicitHeight: 5
            color: window.barColor
            anchors.bottom: parent.bottom
        }

        Rectangle {
            id: cornersArea

            implicitWidth: QsWindow.window?.width - (leftBar.implicitWidth + rightBar.implicitWidth)
            implicitHeight: QsWindow.window?.height - (topBar.implicitHeight + bottomBar.implicitHeight)
            color: "transparent"
            x: leftBar.implicitWidth
            y: topBar.implicitHeight

            Repeater {
                model: [0, 1, 2, 3]

                Corner {
                    required property int modelData
                    corner: modelData
                    color: window.barColor
                }
            }
        }
    }

    component Corner: WrapperItem {
        id: root

        required property int corner
        property real radius: 15
        required property color color

        x: (corner === 0 || corner === 3) ? 0 : parent.width - radius
        y: (corner === 0 || corner === 1) ? 0 : parent.height - radius
        rotation: corner * 90

        Shape {
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                fillColor: root.color
                startX: root.radius

                PathArc {
                    relativeX: -root.radius
                    relativeY: root.radius
                    radiusX: root.radius
                    radiusY: radiusX
                    direction: PathArc.Counterclockwise
                }

                PathLine {
                    relativeX: 0
                    relativeY: -root.radius
                }

                PathLine {
                    relativeX: root.radius
                    relativeY: 0
                }
            }
        }
    }
    component Exclusion: PanelWindow {
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }
}
