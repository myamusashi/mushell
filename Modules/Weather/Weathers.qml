import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import "WeatherItem" as WI

StyledRect {
    id: root

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
	}

    implicitHeight: parent.height
    implicitWidth: GlobalStates.isWeatherPanelOpen ? parent.width * 0.25 : 0
    color: Colours.m3Colors.m3Surface

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
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

    Loader {
        anchors.fill: parent
		active: GlobalStates.isWeatherPanelOpen
		asynchronous: GlobalStates.isWeatherPanelOpen

		sourceComponent: Flickable {
			id: flickable

            anchors.fill: parent
            contentWidth: width
            contentHeight: contentColumn.implicitHeight + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onWheel: function (wheel) {
                    var delta = wheel.angleDelta.y;
                    var scrollAmount = delta > 0 ? -80 : 80;
                    var newPos = parent.contentY + scrollAmount;
                    newPos = Math.max(0, Math.min(newPos, parent.contentHeight - parent.height));
                    parent.contentY = newPos;
                }
                onPressed: function (mouse) {
                    mouse.accepted = false;
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

                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: summaryText.implicitHeight + 20
                    color: Colours.m3Colors.m3SurfaceContainer
                    radius: Appearance.rounding.normal
					visible: Weather.quickSummary !== ""

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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.large
                    visible: (Weather.hourlyForecast && Weather.hourlyForecast.length > 0) || (Weather.dailyForecast && Weather.dailyForecast.length > 0)

                    WI.ForecastHourly {
                        Layout.fillWidth: true
                    }

                    WI.ForecastDaily {
                        Layout.fillWidth: true
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

            StyledRect {
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: 4
                    topMargin: 4
                    bottomMargin: 4
                }

                width: 6
                radius: Appearance.rounding.small
                color: Colours.m3Colors.m3OutlineVariant
                opacity: parent.contentHeight > parent.height ? 0.3 : 0

                StyledRect {
                    width: parent.width
                    height: Math.max(30, flickable.height * (flickable.height / flickable.contentHeight))
                    y: flickable.contentY * (parent.height / flickable.contentHeight)
                    radius: parent.radius
                    color: Colours.m3Colors.m3Primary
                    opacity: 0.5
                }
            }
        }
    }
}
