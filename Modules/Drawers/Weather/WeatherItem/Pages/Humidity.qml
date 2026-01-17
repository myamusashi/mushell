pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    anchors.fill: parent

    property bool isOpen: false

    margin: Appearance.margin.normal
    visible: opacity > 0
    color: Colours.m3Colors.m3Surface
    scale: isOpen ? 1.0 : 0.5
    opacity: isOpen ? 1.0 : 0.0
    transformOrigin: Item.Center

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Component {
        id: loadingIndicator

        LoadingIndicator {
            implicitWidth: 120
            implicitHeight: 120
            status: !Loader.Ready
        }
    }

    Loader {
        active: root.isOpen

        sourceComponent: Column {
            spacing: Appearance.spacing.normal

            Header {
                icon: Lucide.icon_droplet
                title: "Humidity"
                mouseArea.onClicked: root.isOpen = false
            }

            ClippingRectangle {
                anchors.margins: Appearance.margin.normal
                implicitWidth: parent.width
                implicitHeight: parent.height * 0.3
                radius: Appearance.rounding.normal
                color: Colours.m3Colors.m3SurfaceContainer

                ColumnLayout {
                    id: content

                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: "Today's average"
                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.large * 1.5
                    }

                    StyledText {
                        text: Weather.humidity + "%"
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
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

                                    HumiditySlider {
                                        implicitWidth: 30
                                        implicitHeight: 150
                                        value: parent.modelData.humidity
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
                }
            }

            StyledRect {
                implicitWidth: parent.width
                implicitHeight: humidityDescription.contentHeight + 20
                color: Colours.m3Colors.m3Surface
                border {
                    color: Colours.m3Colors.m3OutlineVariant
                    width: 1
                }

                FileView {
                    id: humidityFileDescription

                    path: Qt.resolvedUrl("./Markdown/Humidity.md")
                    watchChanges: true
                }

                StyledText {
                    id: humidityDescription

                    anchors {
                        fill: parent
                        margins: 10
                    }
                    text: humidityFileDescription.text()
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
                implicitHeight: slider.availableHeight * slider.position + Appearance.spacing.small
                radius: slider.trackWidth / 2
                color: slider.trackColor
            }
        }

        handle: MaterialShape {
            x: slider.leftPadding + (slider.availableWidth - width) / 2
            y: slider.topPadding + slider.visualPosition * (slider.availableHeight - height) + Appearance.spacing.small
            implicitWidth: 30
            implicitHeight: 30
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
