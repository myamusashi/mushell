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

    content: Wind {}
    component Wind: Column {
        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        Header {
            icon: "air"
            title: qsTr("Wind")
            onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            margin: 10
            clip: true
            implicitWidth: parent.width
            implicitHeight: content.implicitHeight + 20
            radius: Appearance.rounding.normal
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
                        text: Weather.windSpeed
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: "Km/h"
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    Layout.topMargin: Appearance.margin.large * 2
                    contentWidth: sliderRow.width
                    contentHeight: sliderRow.height
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: sliderRow

                        anchors.centerIn: parent
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
                                required property var modelData

                                spacing: Appearance.spacing.small

                                WindSlider {
                                    implicitWidth: 30
                                    implicitHeight: 150
                                    value: parent.modelData.windSpeed
                                    windShapeRotation: parent.modelData.windDirectionDegrees
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignCenter
                                    text: parent.modelData.windSpeed
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignCenter

                                    text: parent.modelData.windDirectionText
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignCenter

                                    text: TimeAgo.convertTo12HourCompact(parent.modelData.time)
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                }
                            }
                        }
                    }
                }
            }
        }
        WrapperRectangle {
            border {
                color: Colours.m3Colors.m3Outline
                width: 1
            }
            color: Colours.m3Colors.m3Surface
            radius: Appearance.rounding.normal
            implicitWidth: parent.width
            implicitHeight: description.contentHeight + 10
            margin: 20

            StyledText {
                id: description

                text: DetailText.wind
                color: Colours.m3Colors.m3OnSurface
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.fonts.size.normal
            }
        }
    }

    component WindSlider: Slider {
        id: slider

        property alias windShapeRotation: shape.rotation
        property color trackColor: Colours.m3Colors.m3Primary
        property color trackColorInactive: Colours.m3Colors.m3Surface
        property color handleColor: Colours.m3Colors.m3OnPrimary
        property color handleTextColor: Colours.m3Colors.m3Primary
        property real trackWidth: implicitWidth

        hoverEnabled: false
        orientation: Qt.Vertical
        from: 0
        to: 15
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
                implicitHeight: slider.availableHeight * slider.position + shape.height
                radius: slider.trackWidth / 2
                color: slider.trackColor
                WrapperItem {
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: Appearance.margin.small
                    }
                    implicitWidth: 35
                    implicitHeight: 35

                    MaterialShape {
                        id: shape

                        color: Colours.m3Colors.m3OnPrimary
                        shape: MaterialShape.Triangle
                    }
                }
            }
        }

        handle: Item {}
    }
}
