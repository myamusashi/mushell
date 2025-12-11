import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ColumnLayout {
    anchors.fill: parent
    anchors.margins: Appearance.margin.normal
    spacing: Appearance.spacing.normal

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Weather.cityData
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.extraLarge
    }

    RowLayout {
        Layout.fillWidth: false
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        spacing: Appearance.spacing.normal

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            font.pointSize: Appearance.fonts.size.extraLarge * 4
            color: Colours.m3Colors.m3Primary
            icon: Weather.weatherIconData
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Weather.tempData + "°C"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge * 2.5
            font.weight: Font.Bold
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Weather.weatherDescriptionData.charAt(0).toUpperCase() + Weather.weatherDescriptionData.slice(1)
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal * 1.5
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
                model: [
                    {
                        "value": Weather.tempMinData + "° / " + Weather.tempMaxData + "°",
                        "label": "Min / Max"
                    },
                    {
                        "value": Weather.humidityData + "%",
                        "label": "Kelembapan"
                    },
                    {
                        "value": Weather.windSpeedData + " m/s",
                        "label": "Angin"
                    }
                ]

                ColumnLayout {
                    id: weatherPage

                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 5

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: weatherPage.modelData.value
                        color: Colours.m3Colors.m3OnSurface
                        font.weight: Font.Bold
                        font.pixelSize: Appearance.fonts.size.small * 1.5
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: weatherPage.modelData.label
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.small * 1.2
                    }
                }
            }
        }
    }
}
