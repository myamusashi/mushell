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
                icon: Lucide.icon_cloud_rain
                title: "Precipitation"
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
                        text: "Today's amount"
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
                                    values: [...Weather.hourlyForecast]
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
                implicitWidth: 35
                implicitHeight: slider.value === 0 ? 35 / 2 + Appearance.spacing.small : slider.availableHeight * slider.position + 35 / 2 + Appearance.spacing.small
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

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0
                        StyledText {
                            Layout.alignment: Qt.AlignCenter
                            text: Math.round(slider.value)
                            color: slider.handleTextColor
                            font.pixelSize: Appearance.fonts.size.normal
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
