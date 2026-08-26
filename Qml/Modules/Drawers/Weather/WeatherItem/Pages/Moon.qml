pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "Markdown"

Pages {
    id: root

    content: Moon {}

    property real moonRiseProgress: calculateMoonProgress()

    function calculateMoonProgress() {
        var now = new Date();
        var currentMinutes = now.getHours() * 60 + now.getMinutes();

        var moonriseParts = Weather.moonRise.split(":");
        var moonriseMinutes = parseInt(moonriseParts[0]) * 60 + parseInt(moonriseParts[1]);

        var moonsetParts = Weather.moonSet.split(":");
        var moonsetMinutes = parseInt(moonsetParts[0]) * 60 + parseInt(moonsetParts[1]);

        if (currentMinutes < moonriseMinutes) {
            return 0;
        } else if (currentMinutes > moonsetMinutes) {
            return 1;
        } else {
            var dayLength = moonsetMinutes - moonriseMinutes;
            var elapsed = currentMinutes - moonriseMinutes;
            return elapsed / dayLength;
        }
    }

    function getMoonPhaseText(phase) {
        switch (phase) {
        case "New Moon":
            return qsTr("New Moon");
        case "Waxing Crescent":
            return qsTr("Waxing Crescent");
        case "First Quarter":
            return qsTr("First Quarter");
        case "Waxing Gibbous":
            return qsTr("Waxing Gibbous");
        case "Full Moon":
            return qsTr("Full Moon");
        case "Waning Gibbous":
            return qsTr("Waning Gibbous");
        case "Last Quarter":
            return qsTr("Last Quarter");
        case "Waning Crescent":
            return qsTr("Waning Crescent");
        default:
            return phase || qsTr("Unknown");
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.moonRiseProgress = root.calculateMoonProgress()
    }

    component Moon: ScrollView {
        anchors.fill: parent
        anchors.topMargin: 20

        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            anchors.fill: parent
            spacing: Appearance.spacing.normal

            Header {
                icon: "bedtime"
                title: qsTr("Moon")
                onClicked: root.isOpen = false
            }

            WrapperRectangle {
                color: Colours.m3Colors.m3SurfaceContainer
                radius: Appearance.rounding.normal
                implicitWidth: parent.width
                implicitHeight: parent.height * 0.3
                margin: Appearance.margin.normal

                RowLayout {
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignLeft

                        StyledText {
                            text: root.getMoonPhaseText(Weather.moonPhase)
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.extraLarge
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitWidth: illumination.implicitWidth + Appearance.margin.normal * 2
                            implicitHeight: illumination.implicitHeight + 15

                            StyledText {
                                id: illumination

                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Appearance.margin.normal
                                }
                                text: qsTr("Illumination: %1%").arg(Weather.moonIllumination)
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitWidth: moonRise.implicitWidth + Appearance.margin.normal * 2
                            implicitHeight: moonRise.implicitHeight + 15

                            StyledText {
                                id: moonRise

                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Appearance.margin.normal
                                }
                                text: qsTr("Moonrise: %1").arg(Weather.moonRise)
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitWidth: moonSet.implicitWidth + Appearance.margin.normal * 2
                            implicitHeight: moonSet.implicitHeight + 15

                            StyledText {
                                id: moonSet

                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Appearance.margin.normal
                                }
                                text: qsTr("Moonset: %1").arg(Weather.moonSet)
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Image {
                        readonly property var moonPhaseMap: ({
                                "New Moon": "NewMoon",
                                "Waxing Crescent": "WaxingCrescentMoon",
                                "First Quarter": "FirstQuarterMoon",
                                "Waxing Gibbous": "WaxingGibbousMoon",
                                "Full Moon": "FullMoon",
                                "Waning Gibbous": "WaningGibbousMoon",
                                "Last Quarter": "LastQuarterMoon",
                                "Waning Crescent": "WaningCrescentMoon"
                            })

                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 120
                        source: `${Paths.projectRoot}/Assets/weather_icon/${moonPhaseMap[Weather.moonPhase.trim()] ?? "FullMoon"}.svg`
                        sourceSize: Qt.size(120, 120)
                        fillMode: Image.PreserveAspectFit
                        cache: true
                        asynchronous: true
                        smooth: true
                    }
                }
            }

            WrapperRectangle {
                border {
                    color: Colours.m3Colors.m3OutlineVariant
                    width: 1
                }
                color: Colours.m3Colors.m3Surface
                radius: Appearance.rounding.normal
                implicitWidth: parent.width
                implicitHeight: pressureDescription.contentHeight + 20
                margin: 20

                StyledText {
                    id: pressureDescription

                    text: DetailText.moon
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
}
