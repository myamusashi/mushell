pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "WeatherItem/Pages" as WeatherPages
import "WeatherItem" as WI

Item {
    id: root

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
    }

    implicitHeight: parent.height
    implicitWidth: GlobalStates.isWeatherPanelOpen ? parent.width * 0.25 : 0

    readonly property bool anyPageOpen: humidityPages.isOpen || sunPages.isOpen || pressurePages.isOpen || visibilityPages.isOpen || windPages.isOpen || uvIndexPages.isOpen || aqiPages.isOpen || precipitationPages.isOpen || moonPages.isOpen

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Repeater {
        model: [Qt.TopLeftCorner, Qt.BottomLeftCorner]
        Corner {
            required property var modelData

            location: modelData
            extensionSide: Qt.Horizontal
            radius: GlobalStates.isWeatherPanelOpen ? 40 : 0
            color: GlobalStates.drawerColors
        }
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
            active: GlobalStates.isWeatherPanelOpen
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
                            id: humidityCard

                            implicitWidth: 150
                            implicitHeight: 150

                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    humidityPages.zoomOriginX = humidityCard.mapToItem(root, 0, 0).x + humidityCard.width / 2;
                                    humidityPages.zoomOriginY = humidityCard.mapToItem(root, 0, 0).y + humidityCard.height / 2;
                                    humidityPages.isOpen = true;
                                }
                            }
                        }

                        WI.Sun {
                            id: sunCard

                            implicitWidth: 150
                            implicitHeight: 150
                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    sunPages.zoomOriginX = sunCard.mapToItem(root, 0, 0).x + sunCard.width / 2;
                                    sunPages.zoomOriginY = sunCard.mapToItem(root, 0, 0).y + sunCard.height / 2;
                                    sunPages.isOpen = true;
                                }
                            }
                        }

                        WI.Pressure {
                            id: pressureCard

                            implicitWidth: 150
                            implicitHeight: 150
                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    pressurePages.zoomOriginX = pressureCard.mapToItem(root, 0, 0).x + pressureCard.width / 2;
                                    pressurePages.zoomOriginY = pressureCard.mapToItem(root, 0, 0).y + pressureCard.height / 2;
                                    pressurePages.isOpen = true;
                                }
                            }
                        }

                        WI.Visibility {
                            id: visibilityCard

                            implicitWidth: 150
                            implicitHeight: 150
                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    visibilityPages.zoomOriginX = visibilityCard.mapToItem(root, 0, 0).x + visibilityCard.width / 2;
                                    visibilityPages.zoomOriginY = visibilityCard.mapToItem(root, 0, 0).y + visibilityCard.height / 2;
                                    visibilityPages.isOpen = true;
                                }
                            }
                        }

                        WI.Wind {
                            id: windCard

                            implicitWidth: 150
                            implicitHeight: 150
                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    windPages.zoomOriginX = windCard.mapToItem(root, 0, 0).x + windCard.width / 2;
                                    windPages.zoomOriginY = windCard.mapToItem(root, 0, 0).y + windCard.height / 2;
                                    windPages.isOpen = true;
                                }
                            }
                        }

                        WI.UVIndex {
                            id: uvIndexCard

                            implicitWidth: 150
                            implicitHeight: 150
                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    uvIndexPages.zoomOriginX = uvIndexCard.mapToItem(root, 0, 0).x + uvIndexCard.width / 2;
                                    uvIndexPages.zoomOriginY = uvIndexCard.mapToItem(root, 0, 0).y + uvIndexCard.height / 2;
                                    uvIndexPages.isOpen = true;
                                }
                            }
                        }

                        WI.AQI {
                            id: aqiCard

                            implicitWidth: 150
                            implicitHeight: 150
                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    aqiPages.zoomOriginX = aqiCard.mapToItem(root, 0, 0).x + aqiCard.width / 2;
                                    aqiPages.zoomOriginY = aqiCard.mapToItem(root, 0, 0).y + aqiCard.height / 2;
                                    aqiPages.isOpen = true;
                                }
                            }
                        }

                        WI.Precipitation {
                            id: precipitationCard

                            implicitWidth: 150
                            implicitHeight: 150
                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    precipitationPages.zoomOriginX = precipitationCard.mapToItem(root, 0, 0).x + precipitationCard.width / 2;
                                    precipitationPages.zoomOriginY = precipitationCard.mapToItem(root, 0, 0).y + precipitationCard.height / 2;
                                    precipitationPages.isOpen = true;
                                }
                            }
                        }

                        WI.Moon {
                            id: moonCard

                            implicitWidth: 150
                            implicitHeight: 150
                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.anyPageOpen
                                onClicked: {
                                    moonPages.zoomOriginX = moonCard.mapToItem(root, 0, 0).x + moonCard.width / 2;
                                    moonPages.zoomOriginY = moonCard.mapToItem(root, 0, 0).y + moonCard.height / 2;
                                    moonPages.isOpen = true;
                                }
                            }
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

    // Mouse blocker overlay
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

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: humidityPages.isOpen ? 0 : humidityPages.zoomOriginX - humidityPages.width / 2
            y: humidityPages.isOpen ? 0 : humidityPages.zoomOriginY - humidityPages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }

    WeatherPages.Sun {
        id: sunPages

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: sunPages.isOpen ? 0 : sunPages.zoomOriginX - sunPages.width / 2
            y: sunPages.isOpen ? 0 : sunPages.zoomOriginY - sunPages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }

    WeatherPages.Pressure {
        id: pressurePages

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: pressurePages.isOpen ? 0 : pressurePages.zoomOriginX - pressurePages.width / 2
            y: pressurePages.isOpen ? 0 : pressurePages.zoomOriginY - pressurePages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }

    WeatherPages.Visibility {
        id: visibilityPages

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: visibilityPages.isOpen ? 0 : visibilityPages.zoomOriginX - visibilityPages.width / 2
            y: visibilityPages.isOpen ? 0 : visibilityPages.zoomOriginY - visibilityPages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }

    WeatherPages.Wind {
        id: windPages

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: windPages.isOpen ? 0 : windPages.zoomOriginX - windPages.width / 2
            y: windPages.isOpen ? 0 : windPages.zoomOriginY - windPages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }

    WeatherPages.UVIndex {
        id: uvIndexPages

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: uvIndexPages.isOpen ? 0 : uvIndexPages.zoomOriginX - uvIndexPages.width / 2
            y: uvIndexPages.isOpen ? 0 : uvIndexPages.zoomOriginY - uvIndexPages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }

    WeatherPages.AQI {
        id: aqiPages

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: aqiPages.isOpen ? 0 : aqiPages.zoomOriginX - aqiPages.width / 2
            y: aqiPages.isOpen ? 0 : aqiPages.zoomOriginY - aqiPages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }

    WeatherPages.Precipitation {
        id: precipitationPages

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: precipitationPages.isOpen ? 0 : precipitationPages.zoomOriginX - precipitationPages.width / 2
            y: precipitationPages.isOpen ? 0 : precipitationPages.zoomOriginY - precipitationPages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }

    WeatherPages.Moon {
        id: moonPages

        property real zoomOriginX: parent.width / 2
        property real zoomOriginY: parent.height / 2

        anchors.fill: parent
        scale: isOpen ? 1.0 : 0.5
        opacity: isOpen ? 1.0 : 0.0
        transformOrigin: Item.Center

        transform: Translate {
            x: moonPages.isOpen ? 0 : moonPages.zoomOriginX - moonPages.width / 2
            y: moonPages.isOpen ? 0 : moonPages.zoomOriginY - moonPages.height / 2

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on y {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
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
    }
}
