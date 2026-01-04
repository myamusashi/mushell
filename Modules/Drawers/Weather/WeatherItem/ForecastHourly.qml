import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "../../../../Submodules/rounded-polygon-qmljs/material-shapes.js" as MaterialShapes

StyledRect {
    implicitWidth: parent.width
    implicitHeight: content.height
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    color: Colours.m3Colors.m3SurfaceContainer

    ColumnLayout {
        id: content

        implicitWidth: parent.width
        spacing: 0
        visible: Weather.hourlyForecast && Weather.hourlyForecast.length > 0

        RowLayout {
            spacing: Appearance.rounding.small
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.leftMargin: 15
            Layout.topMargin: 20
            Icon {
                type: Icon.Material
                icon: "schedule"
                color: Colours.m3Colors.m3Primary
                font.pointSize: Appearance.fonts.size.large
                font.variableAxes: {
                    "FILL": 10,
                    "opsz": fontInfo.pixelSize,
                    "wght": fontInfo.weight
                }
            }
            StyledText {
                text: "Hourly forecast"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Bold
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            contentWidth: hourlyRow.width
            clip: true

            contentHeight: hourlyRow.height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            RowLayout {
                id: hourlyRow

                spacing: 8

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
                    delegate: StyledRect {
                        id: delegate

                        required property var modelData
                        Layout.preferredWidth: 65
                        Layout.preferredHeight: 110
                        radius: Appearance.rounding.normal

                        readonly property bool isCurrentHour: {
                            const currentHour = new Date().getHours();
                            const timeStr = (modelData.time || "").split(" ")[1] || modelData.time || "";
                            const forecastHour = parseInt(timeStr.split(":")[0] || "0");
                            return currentHour === forecastHour;
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 0
                            spacing: 0

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40

                                ShapeCanvas {
                                    anchors.fill: parent
                                    anchors.rightMargin: 3
                                    color: Colours.m3Colors.m3Primary
                                    roundedPolygon: MaterialShapes.getCookie4Sided()
                                    visible: delegate.isCurrentHour
                                    onProgressChanged: requestPaint()

                                    // force if shape failed to paint
                                    Component.onCompleted: {
                                        roundedPolygon = MaterialShapes.getCookie4Sided();
                                        requestPaint();
                                    }

                                    onVisibleChanged: {
                                        if (visible)
                                            requestPaint();
                                    }
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    text: (parseInt(delegate.modelData.temperature) || 0) + "°"
                                    color: delegate.isCurrentHour ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.size.normal
                                    font.weight: Font.Bold
                                }
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 2
                                StyledText {
                                    text: (parseInt(delegate.modelData.humidity) || 0) + "%"
                                    color: Colours.m3Colors.m3Primary
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.fonts.size.small
                                }
                            }

                            Icon {
                                type: Icon.Weather
                                Layout.alignment: Qt.AlignHCenter
                                font.pointSize: Appearance.fonts.size.large * 1.3
                                color: Colours.m3Colors.m3Primary
                                icon: delegate.modelData.weatherIcon
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: TimeAgo.convertTo12HourCompact((delegate.modelData.time || "").split(" ")[1] || delegate.modelData.time || "")
                                color: Colours.m3Colors.m3OnSurface
                                font.weight: Font.Bold
                                font.pixelSize: Appearance.fonts.size.small
                            }
                        }
                    }
                }
            }
        }
    }
}
