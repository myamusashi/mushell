pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Components.Button

import "Markdown"

Pages {
    id: root

    content: AQI {}
    component AQI: Column {
        id: column

        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        property int selectedTab: 0

        property string description: selectedTab === 0 ? DetailText.usAQI : DetailText.euroAQI

        Header {
            icon: "waves"
            title: qsTr("Air quality")
            mouseArea.onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            margin: 10
            implicitWidth: parent.width
            implicitHeight: parent.height * 0.25
            radius: Appearance.rounding.normal
            color: Colours.m3Colors.m3SurfaceContainer

            ColumnLayout {
                id: content

                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Current conditions")
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    StyledText {
                        text: Weather.europeanAQI
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: Weather.europeanAQICategory
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 3
                    Layout.bottomMargin: 8

                    StyledRect {
                        implicitWidth: parent.width
                        implicitHeight: 5
                        radius: Appearance.rounding.small
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: Colours.m3Colors.m3Green
                            }
                            GradientStop {
                                position: 0.2
                                color: Colours.m3Colors.m3Yellow
                            }
                            GradientStop {
                                position: 0.4
                                color: Colours.m3Colors.m3Orange
                            }
                            GradientStop {
                                position: 0.6
                                color: Colours.m3Colors.m3Red
                            }
                            GradientStop {
                                position: 0.8
                                color: Colours.m3Colors.m3Purple
                            }
                            GradientStop {
                                position: 1.0
                                color: Colours.m3Colors.m3Maroon
                            }
                        }
                    }

                    StyledRect {
                        implicitWidth: 15
                        implicitHeight: 15
                        radius: implicitWidth / 2
                        color: Colours.m3Colors.m3Surface
                        border.width: 2
                        border.color: Colours.m3Colors.m3OnSurface
                        x: {
                            var position = 0;
                            var value = Weather.usAQI;

                            if (value <= 50) {
                                position = (value / 50) * 0.2; // 0-20% of gradient
                            } else if (value <= 100) {
                                position = 0.2 + ((value - 50) / 50) * 0.2; // 20-40%
                            } else if (value <= 150) {
                                position = 0.4 + ((value - 100) / 50) * 0.2; // 40-60%
                            } else if (value <= 200) {
                                position = 0.6 + ((value - 150) / 50) * 0.2; // 60-80%
                            } else if (value <= 300) {
                                position = 0.8 + ((value - 200) / 100) * 0.2; // 80-100%
                            } else {
                                position = Math.min(1.0, 0.8 + ((value - 300) / 200) * 0.2);
                            }

                            return Math.min(Math.max(0, position * parent.width - width / 2), parent.width - width);
                        }
                        y: parent.height / 2 - height / 2
                        Behavior on x {
                            NAnim {}
                        }
                    }
                }

                Repeater {
                    model: [
                        {
                            text: qsTr("United States AQI:"),
                            value: Weather.usAQI
                        },
                        {
                            text: qsTr("European AQi:"),
                            value: Weather.europeanAQI
                        }
                    ]

                    delegate: RowLayout {
                        id: aqiDelegate

                        required property var modelData

                        StyledText {
                            text: aqiDelegate.modelData.text
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.large
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledRect {
                            FontMetrics {
                                id: aqiMetrics

                                font: aqiTextValue.font
                            }
                            implicitWidth: aqiMetrics.advanceWidth(aqiTextValue.text) + 20
                            implicitHeight: aqiMetrics.height + 5
                            radius: Appearance.rounding.full
                            color: Colours.m3Colors.m3Primary

                            StyledText {
                                id: aqiTextValue

                                anchors.centerIn: parent
                                text: aqiDelegate.modelData.value
                                color: Colours.m3Colors.m3OnPrimary
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }
                    }
                }

                ConnectedButtonGroup {
                    id: tabGroup

                    Layout.alignment: Qt.AlignHCenter

                    currentIndex: column.selectedTab
                    model: [qsTr("United States AQI"), qsTr("European AQI")]

                    onClicked: index => column.selectedTab = index
                }
            }
        }

        WrapperRectangle {
            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }
            margin: 20
            radius: Appearance.rounding.small
            color: Colours.m3Colors.m3Surface
            implicitWidth: parent.width
            implicitHeight: aqiDescription.contentHeight + 20

            StyledText {
                id: aqiDescription

                text: column.description
                color: Colours.m3Colors.m3OnSurfaceVariant
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
                font.weight: Font.DemiBold
                font.pixelSize: Appearance.fonts.size.normal
            }
        }
    }
}
