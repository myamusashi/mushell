pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "Markdown"

Pages {
    id: root

    content: UVIndex {}
    component UVIndex: Column {
        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        Header {
            icon: "wb_sunny"
            title: qsTr("UV Index")
            onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            margin: 10
            implicitWidth: parent.width
            implicitHeight: content.width * 0.75
            radius: Appearance.rounding.normal
            clip: true
            color: Colours.m3Colors.m3SurfaceContainer

            ColumnLayout {
                id: content

                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Today's average")
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    StyledText {
                        text: Weather.uvIndex
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: qsTr("Moderate")
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: Appearance.margin.large * 2
                    contentWidth: sliderRow.width
                    contentHeight: sliderRow.height
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: sliderRow

                        spacing: Appearance.spacing.large

                        Repeater {
                            model: ScriptModel {
                                values: (function () {
                                        const currentHour = new Date().getHours();
                                        return Weather.hourlyForecast.filter(function (forecast) {
                                            const timeStr = (forecast.time || "").split(" ")[1] || forecast.time || "";
                                            const forecastHour = parseInt(timeStr.split(":")[0] || "0");
                                            return forecastHour >= currentHour;
                                        });
                                    })()
                            }

                            delegate: ColumnLayout {
                                spacing: Appearance.spacing.normal
                                required property var modelData

                                UVIndexSlider {
                                    implicitWidth: 30
                                    implicitHeight: 150
                                    value: parent.modelData.windSpeed
                                }

                                StyledText {
                                    text: TimeAgo.convertTo12HourCompact(parent.modelData.time)
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        StyledRect {
            implicitWidth: parent.width
            implicitHeight: uvIndexDescription.contentHeight + 20
            color: Colours.m3Colors.m3Surface
            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }

            StyledText {
                id: uvIndexDescription

                anchors.fill: parent
                anchors.margins: 10
                text: DetailText.uvIndex
                color: Colours.m3Colors.m3OnSurface
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.fonts.size.normal
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component UVIndexSlider: Slider {
        id: slider

        property color trackColor: Colours.m3Colors.m3Primary
        property color trackColorInactive: Colours.m3Colors.m3Surface
        property color handleColor: Colours.m3Colors.m3OnPrimary
        property color handleTextColor: Colours.m3Colors.m3Primary
        property real trackWidth: implicitWidth

        hoverEnabled: false
        orientation: Qt.Vertical
        from: 0
        to: 10
        enabled: false

        background: Item {
            anchors.fill: parent

            // inactive
            Rectangle {
                x: slider.leftPadding + (slider.availableWidth - width) / 2
                y: slider.topPadding
                implicitWidth: slider.trackWidth / 2
                implicitHeight: slider.availableHeight
                radius: slider.trackWidth / 2
                color: slider.trackColorInactive
            }

            // active
            Rectangle {
                anchors.bottom: parent.bottom
                x: slider.leftPadding + (slider.availableWidth - width) / 2
                implicitWidth: slider.trackWidth * 1.2
                implicitHeight: slider.availableHeight * slider.position + Appearance.spacing.small + shape.height
                radius: slider.trackWidth / 2
                color: slider.trackColor

                MaterialShape {
                    id: shape

                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: Appearance.margin.small
                    }
                    implicitWidth: 35
                    implicitHeight: 35
                    color: slider.handleColor
                    shape: MaterialShape.Cookie9Sided

                    StyledText {
                        anchors.centerIn: parent
                        text: Math.round(slider.value)
                        color: slider.handleTextColor
                        font.pixelSize: Appearance.fonts.size.medium
                        font.bold: true
                    }
                }
            }
        }

        handle: Item {}
    }
}
