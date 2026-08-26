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

        readonly property var scales: [
            {
                description: DetailText.usAQI,
                value: Weather.usAQI,
                category: Weather.usAQICategory,
                bounds: [50, 100, 150, 200, 300],
                max: 500
            },
            {
                description: DetailText.euroAQI,
                value: Weather.europeanAQI,
                category: Weather.europeanAQICategory,
                bounds: [25, 50, 75, 100, 150],
                max: 250
            }
        ]

        readonly property var currentScale: scales[selectedTab]

        property string description: currentScale.description

        function sliderFraction(value, bounds, max) {
            const segmentCount = bounds.length + 1;
            const segmentWidth = 1 / segmentCount;

            let lowerBound = 0;
            for (let i = 0; i < bounds.length; i++) {
                const upperBound = bounds[i];
                if (value <= upperBound)
                    return (i + (value - lowerBound) / (upperBound - lowerBound)) * segmentWidth;

                lowerBound = upperBound;
            }

            return Math.min(1, (segmentCount - 1 + (value - lowerBound) / (max - lowerBound)) * segmentWidth);
        }

        Header {
            icon: "waves"
            title: qsTr("Air quality")
            onClicked: root.isOpen = false
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
                        text: column.currentScale.value
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: column.currentScale.category
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
                            const scale = column.currentScale;
                            const position = column.sliderFraction(scale.value, scale.bounds, scale.max);

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
