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

    content: Pressure {}
    component Pressure: Column {
        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        Header {
            icon: "compress"
            title: qsTr("Pressure")
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
                    text: qsTr("Current conditions")
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    StyledText {
                        text: Weather.pressure
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: "hPa"
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
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
                                id: hourlyDelegate

                                required property var modelData
                                required property int index
                                spacing: Appearance.spacing.normal

                                PressureSlider {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 30
                                    implicitHeight: 150
                                    value: hourlyDelegate.modelData.pressure
                                    currentPressure: hourlyDelegate.modelData.pressure
                                    currentIndex: hourlyDelegate.index
                                }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: hourlyDelegate.modelData.pressure
                                        color: Colours.m3Colors.m3OnBackground
                                        font.pixelSize: Appearance.fonts.size.normal
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: TimeAgo.convertTo12HourCompact(hourlyDelegate.modelData.time)
                                        color: Colours.m3Colors.m3OnBackground
                                        font.pixelSize: Appearance.fonts.size.normal
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            implicitWidth: parent.width
            implicitHeight: pressureDescription.contentHeight + 20
            color: Colours.m3Colors.m3Surface
            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }

            StyledText {
                id: pressureDescription

                anchors {
                    fill: parent
                    margins: 10
                }
                text: DetailText.pressure
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

    component PressureSlider: Slider {
        id: slider

        property string icon: "arrow_downward"
        property color trackColor: Colours.m3Colors.m3Primary
        property color trackColorInactive: Colours.m3Colors.m3Surface
        property color handleColor: Colours.m3Colors.m3OnPrimary
        property color handleTextColor: Colours.m3Colors.m3Primary
        property real trackWidth: implicitWidth
        property real currentPressure: 0
        property int currentIndex: 0

        function getPressureIcon(): string {
            if (currentIndex === 0) {
                const diff = currentPressure - Weather.pressure;

                if (Math.abs(diff) < 1.0) {
                    return "arrow_forward";  // Stable (diff < 1 hPa)
                } else if (diff > 0) {
                    return "arrow_upward";
                } else {
                    return "arrow_downward";
                }
            } else {
                const previousPressure = Weather.hourlyForecast[currentIndex - 1].pressure;
                const diff = currentPressure - previousPressure;

                if (Math.abs(diff) < 1.0) {
                    return "arrow_forward";
                } else if (diff > 0) {
                    return "arrow_upward";
                } else {
                    return "arrow_downward";
                }
            }
        }

        hoverEnabled: false
        orientation: Qt.Vertical
        from: 00
        to: 1500
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

                MaterialShape {
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: Appearance.margin.small
                    }
                    implicitWidth: 35
                    implicitHeight: 35
                    color: slider.handleColor
                    shape: MaterialShape.Cookie9Sided

                    Icon {
                        type: Icon.Material
                        anchors.centerIn: parent
                        icon: slider.getPressureIcon()
                        color: slider.handleTextColor
                        font.pixelSize: Appearance.fonts.size.large
                        font.bold: true
                    }
                }
            }
        }

        handle: Item {}
    }
}
