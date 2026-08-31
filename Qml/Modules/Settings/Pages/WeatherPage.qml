import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base
import qs.Services

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Weather & Location")

    SettingsCard {
        title: qsTr("Geographic Data")

        SettingRow {
            label: qsTr("Latitude:")
            description: qsTr("Latitude of your location for weather and astronomy data.")

            StyledTextInput {
                text: Configs.weather.latitude
                onTextChanged: Configs.weather.latitude = text
                Layout.preferredWidth: 250
                placeHolderText: "e.g., -6.200000"
                toggleButtonVisible: false
            }
        }

        SettingRow {
            label: qsTr("Longitude:")
            description: qsTr("Longitude of your location for weather and astronomy data.")

            StyledTextInput {
                text: Configs.weather.longitude
                onTextChanged: Configs.weather.longitude = text
                Layout.preferredWidth: 250
                placeHolderText: "e.g., 106.816666"
                toggleButtonVisible: false
            }
        }
    }

    SettingsCard {
        title: qsTr("Astronomy API")

        SettingRow {
            label: qsTr("WeatherAPI.com Key:")
            description: qsTr("API key from WeatherAPI.com for astronomy and forecast data.")

            StyledTextInput {
                text: Configs.weather.astronomyApiKey
                onTextChanged: Configs.weather.astronomyApiKey = text
                Layout.preferredWidth: 300
                placeHolderText: qsTr("Enter your WeatherAPI.com API key")
                toggleButtonVisible: false
            }
        }
    }

    SettingsCard {
        title: qsTr("Sync & Overview")

        SettingRow {
            label: qsTr("Enable Quick Summary Widget:")
            description: qsTr("Show a compact weather summary in quick settings.")

            StyledSwitch {
                checked: Configs.weather.enableQuickSummary
                onCheckedChanged: Configs.weather.enableQuickSummary = checked
            }
        }

        SettingRow {
            label: qsTr("Weather Reload Time (s):")
            description: qsTr("Interval for refreshing weather data, in seconds.")

            StyledText {
                text: {
                    var secs = Configs.weather.reloadTime / 1000;
                    var mins = Math.round(secs / 60);
                    return qsTr("(%1 min)").arg(mins);
                }
                font.pixelSize: Appearance.fonts.size.medium
                color: Colours.m3Colors.m3OnSurfaceVariant
            }

            StyledTextInput {
                text: (Configs.weather.reloadTime / 1000).toString()
                onTextChanged: {
                    var parsed = parseInt(text);
                    if (!isNaN(parsed) && parsed > 0) {
                        Configs.weather.reloadTime = parsed * 1000;
                    }
                }
                Layout.preferredWidth: 200
                toggleButtonVisible: false
            }
        }
    }
}
