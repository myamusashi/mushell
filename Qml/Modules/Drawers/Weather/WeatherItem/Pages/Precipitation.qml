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

    content: Precipitation {}

    component Precipitation: Column {
        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        Header {
            icon: "rainy"
            title: qsTr("Precipitation")
            onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            margin: 10
            color: Colours.m3Colors.m3SurfaceContainer
            clip: true
            implicitWidth: parent.width
            implicitHeight: content.implicitHeight + 20
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: content

                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Today's amount")
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    StyledText {
                        text: Weather.precipitation
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: "mm"
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
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
                                id: precipitationDelegate

                                spacing: Appearance.spacing.normal
                                required property var modelData

                                HumiditySlider {
                                    implicitWidth: 30
                                    implicitHeight: 150
                                    value: precipitationDelegate.modelData.probability
                                }

                                StyledText {
                                    text: TimeAgo.convertTo12HourCompact(precipitationDelegate.modelData.time)
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            implicitWidth: parent.width
            implicitHeight: precipitationDescription.contentHeight + 20
            color: Colours.m3Colors.m3Surface
            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }

            StyledText {
                id: precipitationDescription

                anchors {
                    fill: parent
                    margins: 10
                }
                text: DetailText.precipitation
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

    component HumiditySlider: Slider {
        id: slider

        property color trackColor: Colours.m3Colors.m3Primary
        property color trackColorInactive: Colours.m3Colors.m3Surface
        property color handleColor: Colours.m3Colors.m3OnPrimary
        property color handleTextColor: Colours.m3Colors.m3Primary
        property real trackWidth: implicitWidth

        hoverEnabled: false
        orientation: Qt.Vertical
        from: 0
        to: 100
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

                MaterialShape {
                    id: shape

                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }
                    implicitWidth: 35
                    implicitHeight: 35
                    color: slider.handleColor
                    shape: MaterialShape.Cookie9Sided

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0

                        StyledText {
                            Layout.alignment: Qt.AlignCenter
                            text: Math.round(slider.value)
                            color: slider.handleTextColor
                            font.pixelSize: Appearance.fonts.size.medium
                            font.bold: true
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignCenter
                            text: "%"
                            color: slider.handleTextColor
                            font.pixelSize: Appearance.fonts.size.medium
                            font.bold: true
                        }
                    }
                }
            }
        }

        handle: Item {}
    }
}
