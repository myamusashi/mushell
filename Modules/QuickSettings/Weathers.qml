import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import "WeatherItem" as WI

RowLayout {
    Layout.fillWidth: true
    Layout.topMargin: 10
    spacing: Appearance.spacing.large * 2

    RowLayout {
        spacing: Appearance.spacing.normal

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            font.pointSize: Appearance.fonts.size.extraLarge * 3
            color: Colours.m3Colors.m3Primary
            icon: Weather.weatherIcon
        }

        ColumnLayout {
            spacing: 2

            StyledText {
                text: Weather.temp + "°C"
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.extraLarge * 2.5
                font.weight: Font.Bold
            }

            StyledText {
                text: Weather.weatherDescription.charAt(0).toUpperCase() + Weather.weatherDescription.slice(1)
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
            }

            StyledText {
                text: "Terasa " + Weather.feelsLike + "°C"
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                font.italic: true
            }

            StyledRect {
                Layout.preferredWidth: parent.width
                Layout.topMargin: 10
                Layout.preferredHeight: summaryText.implicitHeight + 20
                color: Colours.m3Colors.m3SurfaceContainerHighest
                radius: 12
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
        }
    }

    Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        color: Colours.m3Colors.m3OutlineVariant
        opacity: 0.5
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.large

        RowLayout {
            spacing: Appearance.spacing.large

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3

                WeatherInfoItem {
                    icon: "water_drop"
                    value: Weather.humidity + "%"
                    label: "Kelembapan"
                }

                WeatherInfoItem {
                    icon: "wb_twilight"
                    value: Weather.sunRise + " / " + "\n" + Weather.sunSet
                    label: "Matahari Terbit/Terbenam"
                }

                WeatherInfoItem {
                    icon: "compress"
                    value: Weather.pressure + " mb"
                    label: "Tekanan"
                }

                WeatherInfoItem {
                    icon: "visibility"
                    value: Weather.visibility.toFixed(2) + " km"
                    label: "Jarak Pandang"
                }

                WeatherInfoItem {
                    icon: "air"
                    value: Weather.windSpeed + " km/h"
                    label: "Angin " + Weather.windDirection
                }

                WeatherInfoItem {
                    icon: "wb_sunny"
                    value: Weather.uvIndex.toString()
                    label: "UV Index"
                    valueColor: Weather.uvIndex >= 6 ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurface
                }

                WeatherInfoItem {
                    icon: "airwave"
                    value: Weather.usAQI
                    label: "Air quality index (US)"
                }

                WeatherInfoItem {
                    icon: "rainy"
                    value: Weather.precipitationDaily + " mm"
                    label: "Curah Hujan"
                }

                WeatherInfoItem {
                    icon: "cloud"
                    value: Weather.cloudCover + "%"
                    label: "Tutupan Awan"
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Colours.m3Colors.m3OutlineVariant
            opacity: 0.5
            visible: (Weather.hourlyForecast && Weather.hourlyForecast.length > 0) || (Weather.dailyForecast && Weather.dailyForecast.length > 0)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            WI.ForecastHourly {
                Layout.fillWidth: true
            }

            WI.ForecastDaily {
                Layout.fillWidth: true
                Layout.topMargin: 10
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    component WeatherInfoItem: ColumnLayout {
        id: infoItem

        property string icon: "info"
        property string value: ""
        property string label: ""
        property color valueColor: Colours.m3Colors.m3OnSurface

        spacing: 2

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            font.pointSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3Primary
            icon: infoItem.icon
            opacity: 0.7
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: infoItem.value
            color: infoItem.valueColor
            font.weight: Font.Bold
            font.pixelSize: Appearance.fonts.size.normal
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: infoItem.label
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.maximumWidth: 80
        }
    }
}
