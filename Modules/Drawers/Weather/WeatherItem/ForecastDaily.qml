import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

StyledRect {
    implicitWidth: parent.width
    implicitHeight: content.height
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    color: Colours.m3Colors.m3SurfaceContainer

    ColumnLayout {
        id: content

        implicitWidth: parent.width
        spacing: Appearance.spacing.small
        visible: Weather.dailyForecast && Weather.dailyForecast.length > 0

        RowLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.leftMargin: 20
            Layout.topMargin: 20
            spacing: Appearance.rounding.small

            Icon {
                type: Icon.Lucide
                icon: Lucide.icon_calendar_days
                font.pointSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3Primary
            }

            StyledText {
                text: "Daily Forecast"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Bold
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            clip: true
            contentWidth: dailyRow.width
            contentHeight: dailyRow.height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            RowLayout {
                id: dailyRow

                spacing: 6

                Repeater {
                    model: ScriptModel {
                        values: [...Weather.dailyForecast]
                    }
                    delegate: StyledRect {
                        id: delegate

                        required property var modelData

                        color: Colours.withAlpha(Colours.m3Colors.m3Surface, 0.2)
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 180
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.bottomMargin: 10
                        radius: Appearance.rounding.full

                        ColumnLayout {
                            anchors.centerIn: parent
                            anchors.margins: 5
                            spacing: Appearance.rounding.small

                            ColumnLayout {
                                Layout.alignment: Qt.AlignCenter
                                Layout.margins: 0
                                spacing: 0

                                StyledText {
                                    text: (parseInt(delegate.modelData.maxTemp) || 0) + "°"
                                    color: Colours.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.size.normal
                                    font.weight: Font.Bold
                                }
                                StyledText {
                                    text: (parseInt(delegate.modelData.minTemp) || 0) + "°"
                                    color: Colours.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.size.normal
                                }
                            }

                            Icon {
                                type: Icon.Weather
                                Layout.alignment: Qt.AlignHCenter
                                font.pointSize: Appearance.fonts.size.extraLarge
                                color: Colours.m3Colors.m3Primary
                                icon: delegate.modelData.weatherIcon
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignCenter
                                text: (parseInt(delegate.modelData.humidity) || 0) + "%"
                                color: Colours.m3Colors.m3Primary
                                font.weight: Font.Bold
                                font.pixelSize: Appearance.fonts.size.small
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignCenter
                                text: {
                                    const date = delegate.modelData.date || "";
                                    if (!date)
                                        return "";

                                    const today = new Date().toDateString();
                                    const forecastDate = new Date(date);

                                    if (forecastDate.toDateString() === today) {
                                        return "Today";
                                    }

                                    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                                    return days[forecastDate.getDay()];
                                }
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.medium
                                font.weight: Font.Bold
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignCenter
                                text: {
                                    const date = delegate.modelData.date || "";
                                    if (!date)
                                        return "";
                                    const parts = date.split("-");
                                    if (parts.length >= 3) {
                                        return parts[2] + "/" + parts[1];
                                    }
                                    return date;
                                }
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.medium
                            }
                        }
                    }
                }
            }
        }
    }
}
