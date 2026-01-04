pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import "WeatherItem" as WI

Item {
    id: root

    implicitHeight: parent.height
    implicitWidth: GlobalStates.isWeatherPanelOpen ? parent.width * 0.25 : 0

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
    }

    Corner {
        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isWeatherPanelOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomLeftCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isWeatherPanelOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    IpcHandler {
        target: "weather"
        function open() {
            GlobalStates.openPanel("weather");
        }
        function close() {
            GlobalStates.closePanel("weather");
        }
        function toggle() {
            GlobalStates.togglePanel("weather");
        }
    }

    GlobalShortcut {
        name: "weather"
        onPressed: GlobalStates.togglePanel("weather")
    }

    StyledRect {
        anchors.fill: parent
        clip: true
        radius: 0
        color: GlobalStates.drawerColors

        Loader {
            id: mainLoader

            anchors.fill: parent
            active: root.visible && GlobalStates.isWeatherPanelOpen
            asynchronous: true

            sourceComponent: Flickable {
                id: flickable

                anchors.fill: parent
                contentWidth: width
                contentHeight: contentColumn.implicitHeight + 40
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    id: scrollBar

                    policy: ScrollBar.AsNeeded
                    anchors {
                        right: flickable.right
                        top: flickable.top
                        bottom: flickable.bottom
                    }
                    width: 6

                    contentItem: StyledRect {
                        implicitWidth: 6
                        radius: Appearance.rounding.small
                        color: Colours.m3Colors.m3Primary
                        opacity: scrollBar.pressed ? 0.8 : 0.5
                    }

                    background: StyledRect {
                        implicitWidth: 6
                        radius: Appearance.rounding.small
                        color: Colours.m3Colors.m3OutlineVariant
                        opacity: 0.3
                    }
                }

                ColumnLayout {
                    id: contentColumn

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 20
                    }
                    spacing: Appearance.spacing.normal

                    Headers {}

                    Loader {
                        id: summaryLoader

                        Layout.fillWidth: true
                        active: Weather.quickSummary !== ""
                        visible: active
                        asynchronous: true

                        sourceComponent: StyledRect {
                            implicitHeight: summaryText.implicitHeight + 20
                            color: Colours.m3Colors.m3SurfaceContainer
                            radius: Appearance.rounding.normal

                            StyledText {
                                id: summaryText

                                anchors.fill: parent
                                anchors.margins: 10
                                text: Weather.quickSummary
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.small
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignLeft
                            }
                        }
                    }

                    Loader {
                        id: forecastLoader

                        Layout.fillWidth: true
                        active: (Weather.hourlyForecast && Weather.hourlyForecast.length > 0) || (Weather.dailyForecast && Weather.dailyForecast.length > 0)
                        visible: active
                        asynchronous: true

                        sourceComponent: ColumnLayout {
                            spacing: Appearance.spacing.large

                            WI.ForecastHourly {
                                Layout.fillWidth: true
                            }

                            WI.ForecastDaily {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        columns: 2
                        columnSpacing: Appearance.spacing.large
                        rowSpacing: Appearance.spacing.large

                        WI.Humidity {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.Sun {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.Pressure {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.Visibility {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.Wind {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.UVIndex {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.AQI {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.Precipitation {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.Moon {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                        WI.Cloudiness {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredHeight: 20
                    }
                }
            }
        }
    }
}
