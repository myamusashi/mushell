import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ColumnLayout {
    anchors.fill: parent
    anchors.margins: Appearance.margin.normal
    spacing: Appearance.spacing.normal

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Weather.cityData
        color: Themes.m3Colors.onSurface
        font.pixelSize: Appearance.fonts.extraLarge
    }

    RowLayout {
        Layout.fillWidth: false
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        spacing: Appearance.spacing.normal

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            font.pointSize: Appearance.fonts.extraLarge * 4
            color: Themes.m3Colors.primary
            icon: Weather.weatherIconData
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Weather.tempData + "°C"
            color: Themes.m3Colors.primary
            font.pixelSize: Appearance.fonts.extraLarge * 2.5
            font.weight: Font.Bold
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Weather.weatherDescriptionData.charAt(0).toUpperCase(
                  ) + Weather.weatherDescriptionData.slice(1)
        color: Themes.m3Colors.onSurfaceVariant
        font.pixelSize: Appearance.fonts.normal * 1.5
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    Item {
        Layout.fillWidth: true
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        color: "transparent"

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.large * 5

            Repeater {
                model: [{
                        "value": Weather.tempMinData + "° / " + Weather.tempMaxData + "°",
                        "label": "Min / Max"
                    }, {
                        "value": Weather.humidityData + "%",
                        "label": "Kelembapan"
                    }, {
                        "value": Weather.windSpeedData + " m/s",
                        "label": "Angin"
                    }]

                ColumnLayout {
                    id: weatherPage

                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 5

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: weatherPage.modelData.value
                        color: Themes.m3Colors.onSurface
                        font.weight: Font.Bold
                        font.pixelSize: Appearance.fonts.small * 1.5
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: weatherPage.modelData.label
                        color: Themes.m3Colors.onSurfaceVariant
                        font.pixelSize: Appearance.fonts.small * 1.2
                    }
                }
            }
        }
    }
}
