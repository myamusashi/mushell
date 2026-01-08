pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import QtGraphs

ClippingRectangle {
    id: root

    implicitWidth: columnLayout.width
    implicitHeight: columnLayout.implicitHeight
    color: Colours.m3Colors.m3SurfaceContainer
    radius: Appearance.rounding.small

    property alias content: columnLayout
    property int currentTab: 0

    ColumnLayout {
        id: columnLayout

        anchors.left: parent.left
        anchors.top: parent.top
        width: 450
        spacing: 0

        Header {
            Layout.fillWidth: true
            icon: "browse_activity"
            text: "Performance"
            condition: root.visible
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            ColumnLayout {
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: Appearance.spacing.small

                Item {
                    Layout.fillHeight: true
                }

                Repeater {
                    model: [
                        {
                            name: "CPU",
                            index: 0,
                            value: SystemUsage.cpuPerc + "%"
                        },
                        {
                            name: "GPU",
                            index: 1,
                            value: SystemUsage.gpuUsage + "%"
                        },
                        {
                            name: "VRAM",
                            index: 2,
                            value: SystemUsage.vramUsed + " MB"
                        },
                        {
                            name: "RAM",
                            index: 3,
                            value: SystemUsage.memPercent.toFixed(1) + "%"
                        }
                    ]

                    delegate: StyledRect {
                        id: tabDelegate

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        color: root.currentTab === modelData.index ? Colours.m3Colors.m3PrimaryContainer : "transparent"
                        radius: Appearance.rounding.small

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: tabDelegate.modelData.name
                                font.pixelSize: Appearance.fonts.size.small
                                font.weight: Font.Medium
                                color: root.currentTab === tabDelegate.modelData.index ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: tabDelegate.modelData.value
                                font.pixelSize: Appearance.fonts.size.large
                                font.weight: Font.Bold
                                color: root.currentTab === tabDelegate.modelData.index ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurface
                            }
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.currentTab = tabDelegate.modelData.index
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: Appearance.spacing.large

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.visible
                    sourceComponent: Graph {
                        metricType: root.currentTab
                    }
                }
            }
        }
    }

    component Graph: Item {
        id: graph

        required property int metricType

        property int maxPoints: 30
        property int counter: -1
        property real currentValue: 0

        function pushValue() {
            counter += 1;

            switch (metricType) {
            case 0:
                currentValue = SystemUsage.cpuPerc;
                break;
            case 1:
                currentValue = SystemUsage.gpuUsage;
                break;
            case 2:
                currentValue = SystemUsage.vramUsed / 100;
                break;
            case 3:
                currentValue = SystemUsage.memPercent;
                break;
            }

            dataPoints.append(counter, currentValue);

            if (dataPoints.count > maxPoints + 1)
                dataPoints.removeMultiple(0, dataPoints.count - maxPoints - 1);

            axisX.min = Math.max(0, counter - maxPoints);
            axisX.max = counter;
        }

        Component.onCompleted: pushValue()

        Connections {
            target: SystemUsage
            enabled: root.visible

            function onCpuPercChanged() {
                graph.pushValue();
            }
        }

        onMetricTypeChanged: {
            dataPoints.clear();
            counter = -1;
            pushValue();
        }

        Rectangle {
            anchors.fill: parent
            border {
                color: Colours.m3Colors.m3Primary
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
                spacing: 4
                z: 1

                Rectangle {
                    width: 12
                    height: 12
                    color: {
                        switch (graph.metricType) {
                        case 0:
                            return Colours.m3Colors.m3Blue;
                        case 1:
                            return Colours.m3Colors.m3Green;
                        case 2:
                            return Colours.m3Colors.m3Red;
                        case 3:
                            return Colours.m3Colors.m3Yellow;
                        }
                    }
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: {
                        switch (graph.metricType) {
                        case 0:
                            return "CPU";
                        case 1:
                            return "GPU";
                        case 2:
                            return "VRAM";
                        case 3:
                            return "RAM";
                        }
                    }
                    color: {
                        switch (graph.metricType) {
                        case 0:
                            return Colours.m3Colors.m3Blue;
                        case 1:
                            return Colours.m3Colors.m3Green;
                        case 2:
                            return Colours.m3Colors.m3Red;
                        case 3:
                            return Colours.m3Colors.m3Yellow;
                        }
                    }
                    font.pixelSize: Appearance.fonts.size.small
                    font.bold: true
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
                    id: dataPoints

                    color: {
                        switch (graph.metricType) {
                        case 0:
                            return Colours.m3Colors.m3Blue;
                        case 1:
                            return Colours.m3Colors.m3Green;
                        case 2:
                            return Colours.m3Colors.m3Red;
                        case 3:
                            return Colours.m3Colors.m3Yellow;
                        }
                    }
                    width: 2
                }
            }
        }
    }
}
