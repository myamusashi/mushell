pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    anchors.fill: parent

    property bool isOpen: false
    property string description: ""
    property real moonriseProgress: calculateMoonProgress()

    margin: Appearance.margin.normal
    visible: opacity > 0
    color: Colours.m3Colors.m3Surface
    scale: isOpen ? 1.0 : 0.5
    opacity: isOpen ? 1.0 : 0.0
    transformOrigin: Item.Center

    Component.onCompleted: console.log("Moon names: " + Weather.moonPhase)

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

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.moonriseProgress = root.calculateMoonProgress()
    }

    Component {
        id: loadingIndicator

        LoadingIndicator {
            implicitWidth: 120
            implicitHeight: 120
            status: !Loader.Ready
        }
    }

    FileView {
        path: Qt.resolvedUrl("./Markdown/Moon.md")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.description = text()
    }

    Loader {
        active: root.isOpen
        sourceComponent: Column {
            spacing: Appearance.spacing.normal

            Header {
                icon: Lucide.icon_moon
                title: "Moon"
                mouseArea.onClicked: root.isOpen = false
            }

            WrapperRectangle {
                color: Colours.m3Colors.m3SurfaceContainer
                radius: Appearance.rounding.normal
                implicitWidth: parent.width
                implicitHeight: parent.height * 0.2
                margin: Appearance.margin.normal

                RowLayout {
                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignLeft

                        StyledText {
                            text: Weather.moonPhase
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.extraLarge
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitWidth: illumination.contentWidth + 20
                            implicitHeight: illumination.contentHeight + 15

                            StyledText {
                                id: illumination

                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Appearance.margin.normal
                                }
                                text: `Illumination: ${Weather.moonIllumination}%`
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitWidth: moonRise.contentWidth + 20
                            implicitHeight: moonRise.contentHeight + 15

                            StyledText {
                                id: moonRise

                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Appearance.margin.normal
                                }
                                text: `Moonrise: ${Weather.moonRise}`
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitWidth: moonSet.contentWidth + 20
                            implicitHeight: moonSet.contentHeight + 15

                            StyledText {
                                id: moonSet

                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Appearance.margin.normal
                                }
                                text: `Moonset: ${Weather.moonSet}`
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Image {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 120
                        source: `root:/Assets/weather_icon/${Weather.moonPhase.trim().replace(/ /g, '')}Moon.svg`
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

                    text: root.description
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
