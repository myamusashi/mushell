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
    property string descriptions: ""

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

    FileView {
        path: Qt.resolvedUrl("./Markdown/Pressure.md")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.descriptions = text()
    }

    Loader {
        active: root.isOpen

        sourceComponent: Column {
            spacing: Appearance.spacing.normal

            Header {
                icon: Lucide.icon_fold_vertical
                title: "Pressure"
                mouseArea.onClicked: root.isOpen = false
            }

            ClippingRectangle {
                anchors.margins: Appearance.margin.normal
                implicitWidth: parent.width
                implicitHeight: content.implicitHeight + content.anchors.margins * 2
                radius: Appearance.rounding.normal
                color: Colours.m3Colors.m3SurfaceContainer

                ColumnLayout {
                    id: content

                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: "Current conditions"
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
                                    values: [...Weather.hourlyForecast]
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
                    text: root.descriptions
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
            }
        }

        handle: MaterialShape {
            x: slider.leftPadding + (slider.availableWidth - width) / 2
            y: slider.topPadding + slider.visualPosition * (slider.availableHeight - height) + 10
            implicitWidth: 30
            implicitHeight: 30
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
