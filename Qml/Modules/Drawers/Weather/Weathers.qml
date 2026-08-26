pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "WeatherItem/Pages" as WeatherPages
import "WeatherItem" as WeatherItems

Item {
    id: root

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
        bottomMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
        topMargin: (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) + Configs.bar.barHeight
    }

    readonly property bool anyPageOpen: humidityPages.isOpen || sunPages.isOpen || pressurePages.isOpen || visibilityPages.isOpen || windPages.isOpen || uvIndexPages.isOpen || aqiPages.isOpen || precipitationPages.isOpen || moonPages.isOpen

    implicitHeight: parent.height
    implicitWidth: GlobalStates.isWeatherPanelOpen ? parent.width * 0.25 : 0
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.TopLeftCorner
        location2: Qt.BottomLeftCorner
        extensionSide: Qt.Horizontal
        active: GlobalStates.isWeatherPanelOpen
    }

    WrapperRectangle {
        id: rect

        anchors.fill: parent
        radius: 0
        clip: true
        color: GlobalStates.drawerColors

        Flickable {
            id: flickable

            contentWidth: width
            contentHeight: contentColumn.implicitHeight + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                id: scrollBar

                anchors {
                    right: flickable.right
                    top: flickable.top
                    bottom: flickable.bottom
                }

                policy: ScrollBar.AsNeeded
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

                visible: GlobalStates.isWeatherPanelOpen
                spacing: Appearance.spacing.normal

                Headers {}

                Loader {
                    id: summaryLoader

                    Layout.fillWidth: true
                    active: Configs.weather.enableQuickSummary && GlobalStates.isWeatherPanelOpen
                    asynchronous: true
                    sourceComponent: WrapperRectangle {
                        implicitHeight: summaryText.implicitHeight + 20
                        color: Colours.m3Colors.m3SurfaceContainer
                        radius: Appearance.rounding.normal
                        margin: Appearance.margin.normal

                        StyledText {
                            id: summaryText

                            text: Weather.getQuickSummary()
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.small
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: ((Weather.hourlyForecast && Weather.hourlyForecast.length > 0) || (Weather.dailyForecast && Weather.dailyForecast.length > 0)) && GlobalStates.isWeatherPanelOpen
                    asynchronous: true
                    sourceComponent: ColumnLayout {
                        spacing: Appearance.spacing.large

                        WeatherItems.ForecastHourly {
                            Layout.fillWidth: true
                        }

                        WeatherItems.ForecastDaily {
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

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        columns: 2
                        columnSpacing: Appearance.spacing.large
                        rowSpacing: Appearance.spacing.large

                        Card {
                            zoomPage: humidityPages
                            content: WeatherItems.Humidity {}
                        }
                        Card {
                            zoomPage: sunPages
                            content: WeatherItems.Sun {}
                        }
                        Card {
                            zoomPage: pressurePages
                            content: WeatherItems.Pressure {}
                        }
                        Card {
                            zoomPage: visibilityPages
                            content: WeatherItems.Visibility {}
                        }
                        Card {
                            zoomPage: windPages
                            content: WeatherItems.Wind {}
                        }
                        Card {
                            zoomPage: uvIndexPages
                            content: WeatherItems.UVIndex {}
                        }
                        Card {
                            zoomPage: aqiPages
                            content: WeatherItems.AQI {}
                        }
                        Card {
                            zoomPage: precipitationPages
                            content: WeatherItems.Precipitation {}
                        }
                        Card {
                            zoomPage: moonPages
                            content: WeatherItems.Moon {}
                        }

                        WeatherItems.Cloudiness {
                            implicitWidth: 150
                            implicitHeight: 150
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 20
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.anyPageOpen
        enabled: root.anyPageOpen
        hoverEnabled: true

        onClicked: {}
        onPressed: {}
        onReleased: {}
    }

    WeatherPages.Humidity {
        id: humidityPages
    }

    WeatherPages.Sun {
        id: sunPages
    }

    WeatherPages.Pressure {
        id: pressurePages
    }

    WeatherPages.Visibility {
        id: visibilityPages
    }

    WeatherPages.Wind {
        id: windPages
    }

    WeatherPages.AQI {
        id: aqiPages
    }

    WeatherPages.Precipitation {
        id: precipitationPages
    }

    WeatherPages.Moon {
        id: moonPages
    }

    WeatherPages.UVIndex {
        id: uvIndexPages
    }

    component Card: Item {
        id: cardRoot

        default property alias content: contentLoader.sourceComponent
        required property var zoomPage

        implicitWidth: 150
        implicitHeight: 150

        Loader {
            id: contentLoader

            anchors.fill: parent
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !root.anyPageOpen
            onClicked: {
                cardRoot.zoomPage.zoomOriginX = cardRoot.mapToItem(root, 0, 0).x + cardRoot.width / 2;
                cardRoot.zoomPage.zoomOriginY = cardRoot.mapToItem(root, 0, 0).y + cardRoot.height / 2;
                cardRoot.zoomPage.isOpen = true;
            }
        }
    }
}
