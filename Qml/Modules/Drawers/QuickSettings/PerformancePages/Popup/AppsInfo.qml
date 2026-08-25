import QtGraphs
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    icon: "apps"
    text: qsTr("Installed apps")

    content: ColumnLayout {
        PieChart {
            implicitWidth: parent.width
            implicitHeight: 200

            graphicalAppCount: DesktopEntries.applications.values.filter(app => !app.runInTerminal).length
            terminalAppCount: DesktopEntries.applications.values.filter(app => app.runInTerminal).length
        }

        RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Repeater {
                model: [
                    {
                        color: Colours.m3Colors.m3Green,
                        text: qsTr("Graphic User Interfaces")
                    },
                    {
                        color: Qt.alpha(Colours.m3Colors.m3Green, 0.5),
                        text: qsTr("Terminal User Interfaces")
                    }
                ]

                delegate: RowLayout {
                    required property var modelData

                    StyledRect {
                        color: parent.modelData.color
                        implicitWidth: 15
                        implicitHeight: 15
                    }

                    StyledText {
                        text: parent.modelData.text
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }
            }
        }
    }

    component PieChart: GraphsView {
        id: pieChart

        required property int graphicalAppCount
        required property int terminalAppCount

        theme: GraphsTheme {
            colorScheme: GraphsTheme.ColorScheme.Dark
            theme: GraphsTheme.Theme.QtGreen
        }

        PieSeries {
            id: pieSeries

            holeSize: 0.5

            PieSlice {
                label: pieChart.graphicalAppCount
                value: pieChart.graphicalAppCount
                color: Colours.m3Colors.m3Green
                borderColor: "transparent"
                labelVisible: true
                labelColor: "white"
                labelPosition: PieSlice.LabelPosition.Outside
                labelArmLengthFactor: 0.3
                explodeDistanceFactor: 0.02
            }

            PieSlice {
                label: pieChart.terminalAppCount
                value: pieChart.terminalAppCount
                color: Qt.alpha(Colours.m3Colors.m3Green, 0.5)
                borderColor: "transparent"
                labelVisible: true
                labelColor: "white"
                labelPosition: PieSlice.LabelPosition.Outside
                labelArmLengthFactor: 0.15
                explodeDistanceFactor: 0.02
            }
        }
    }
}
