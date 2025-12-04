import QtQuick
import QtGraphs
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Configs
import qs.Services

ClippingRectangle {
    id: root

    implicitWidth: columnLayout.width
    implicitHeight: columnLayout.implicitHeight
    color: Themes.m3Colors.m3SurfaceContainer
    radius: Appearance.rounding.small

    property alias content: columnLayout

    ColumnLayout {
        id: columnLayout

        anchors.left: parent.left
        anchors.top: parent.top
        width: 450
        spacing: 0

        Header {
            icon: "browse_activity"
            text: "Performance"
            condition: root.visible
        }

        RowLayout {
            id: row

            Layout.fillHeight: true
            Layout.fillWidth: true
            GridLayout {
                Layout.fillWidth: true
                Layout.margins: 12
                rows: 2
                columns: 2
                rowSpacing: Appearance.spacing.large
                columnSpacing: Appearance.spacing.large

                CPU {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }

                GPU {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }

                VRAM {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }

                RAM {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }
            }

            Graph {
                Layout.preferredWidth: parent.width / 2
                Layout.fillHeight: true
            }
        }
    }

    component Graph: Item {
        id: graph
        Layout.preferredHeight: 200
        Layout.margins: 12

        property int maxPoints: 30
        property int counter: -1

        property real cpuValue: 0
        property real gpuValue: 0
        property real vramValue: 0
        property real ramValue: 0

        function pushValues() {
            counter += 1

            cpuValue = SystemUsage.cpuPerc
            gpuValue = SystemUsage.gpuUsage
            vramValue = SystemUsage.vramUsed / 100
            ramValue = SystemUsage.memPercent

            cpuPoints.append(counter, cpuValue)
            gpuPoints.append(counter, gpuValue)
            vramPoints.append(counter, vramValue)
            ramPoints.append(counter, ramValue)

            // Remove old points
            if (cpuPoints.count > maxPoints + 1) {
                cpuPoints.removeMultiple(0, cpuPoints.count - maxPoints - 1)
                gpuPoints.removeMultiple(0, gpuPoints.count - maxPoints - 1)
                vramPoints.removeMultiple(0, vramPoints.count - maxPoints - 1)
                ramPoints.removeMultiple(0, ramPoints.count - maxPoints - 1)
            }

            axisX.min = Math.max(0, counter - maxPoints)
            axisX.max = counter
        }

        Component.onCompleted: pushValues()

        Connections {
            target: SystemUsage
            function onCpuPercChanged() {
                graph.pushValues()
            }
        }

        Rectangle {
            anchors.fill: parent
            border {
                color: Themes.m3Colors.m3Primary
                width: 1
            }
            color: "transparent"
            radius: Appearance.rounding.small * 0.5

            Row {
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: 8
                }
                spacing: 12
                z: 1

                Row {
                    spacing: 4
                    Rectangle {
                        width: 12
                        height: 12
                        color: Themes.m3Colors.m3Blue
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "CPU"
                        color: Themes.m3Colors.m3Blue
                        font.pixelSize: Appearance.fonts.small
                        font.bold: true
                    }
                }

                Row {
                    spacing: 4
                    Rectangle {
                        width: 12
                        height: 12
                        color: Themes.m3Colors.m3Green
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "GPU"
                        color: Themes.m3Colors.m3Green
                        font.pixelSize: Appearance.fonts.small
                        font.bold: true
                    }
                }

                Row {
                    spacing: 4
                    Rectangle {
                        width: 12
                        height: 12
                        color: Themes.m3Colors.m3Red
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "VRAM"
                        color: Themes.m3Colors.m3Red
                        font.pixelSize: Appearance.fonts.small
                        font.bold: true
                    }
                }

                Row {
                    spacing: 4
                    Rectangle {
                        width: 12
                        height: 12
                        color: Themes.m3Colors.m3Yellow
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "RAM"
                        color: Themes.m3Colors.m3Yellow
                        font.pixelSize: Appearance.fonts.small
                        font.bold: true
                    }
                }
            }

            GraphsView {
                id: graphView
                anchors.fill: parent

                marginBottom: 1
                marginTop: 1
                marginLeft: 1
                marginRight: 1

                theme: GraphsTheme {
                    backgroundVisible: false
                    plotAreaBackgroundColor: "transparent"
                    gridVisible: true
                    borderWidth: 0
                }

                axisX: ValueAxis {
                    id: axisX
                    visible: false
                    lineVisible: false
                    gridVisible: false
                    subGridVisible: false
                }

                axisY: ValueAxis {
                    id: axisY
                    visible: false
                    lineVisible: false
                    gridVisible: false
                    subGridVisible: false
                    max: 100
                    min: 0
                }

                LineSeries {
                    id: cpuPoints
                    color: Themes.m3Colors.m3Blue
                    width: 2
                }

                LineSeries {
                    id: gpuPoints
                    color: Themes.m3Colors.m3Green
                    width: 2
                }

                LineSeries {
                    id: vramPoints
                    color: Themes.m3Colors.m3Red
                    width: 2
                }

                LineSeries {
                    id: ramPoints
                    color: Themes.m3Colors.m3Yellow
                    width: 2
                }
            }
        }
    }

    component CPU: PerformanceTab {
        text: "CPU"
        percentage: SystemUsage.cpuPerc + "%"
    }

    component GPU: PerformanceTab {
        text: "GPU"
        percentage: SystemUsage.gpuUsage + "%"
    }

    component VRAM: PerformanceTab {
        text: "VRAM"
        percentage: SystemUsage.vramUsed + " MB"
    }

    component RAM: PerformanceTab {
        text: "RAM"
        percentage: SystemUsage.memPercent.toFixed(1) + "%"
    }

    component PerformanceTab: ColumnLayout {
        id: perf

        required property string text
        required property string percentage

        spacing: Appearance.spacing.normal

        Text {
            text: perf.text
            font.pixelSize: Appearance.fonts.normal
            font.weight: Font.Medium
            color: Themes.m3Colors.m3OnSurface
            Layout.fillWidth: true
        }

        Text {
            text: perf.percentage
            font.pixelSize: Appearance.fonts.large
            font.weight: Font.Bold
            color: Themes.m3Colors.m3Primary
            Layout.fillWidth: true
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }
}
