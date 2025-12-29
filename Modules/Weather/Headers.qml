import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    ColumnLayout {
        Layout.preferredWidth: 240
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            spacing: Appearance.spacing.small

            StyledText {
                text: Weather.temp + "°"
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
            }
            MaterialIcon {
                icon: Weather.weatherIcon
                font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
                color: Colours.m3Colors.m3Primary
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
            spacing: Appearance.spacing.normal

            RowLayout {
                spacing: Appearance.spacing.small
                MaterialIcon {
                    icon: "arrow_upward"
                    color: Colours.m3Colors.m3OnSurface
                    font.pointSize: Appearance.fonts.size.small
                }
                StyledText {
                    text: Weather.tempMax + "°"
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                }
            }

            RowLayout {
                spacing: Appearance.spacing.small
                MaterialIcon {
                    icon: "arrow_downward"
                    color: Colours.m3Colors.m3OnSurface
                    font.pointSize: Appearance.fonts.size.small
                }
                StyledText {
                    text: Weather.tempMin + "°"
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                }
            }
        }
    }

    ColumnLayout {
        Layout.preferredWidth: 240
        Layout.fillHeight: true
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            text: Weather.weatherCondition
            font.weight: Font.DemiBold
            font.pixelSize: Appearance.fonts.size.medium
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            text: "Feels like " + Weather.feelsLike + "°"
            font.pixelSize: Appearance.fonts.size.small
            color: Colours.m3Colors.m3OnSurface
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignRight
            spacing: Appearance.spacing.small

            MaterialIcon {
                icon: "update"
                font.pointSize: Appearance.fonts.size.small
                color: Colours.m3Colors.m3OnSurface
            }
			StyledText {
				id: time

                text: TimeAgo.timeAgoWithIfElse(Weather.lastUpdateWeather)
                font.pixelSize: Appearance.fonts.size.small
				color: Colours.m3Colors.m3OnSurface

				Timer {
                    interval: 60000
                    running: true
                    repeat: true
                    onTriggered: time.text = TimeAgo.timeAgoWithIfElse(Weather.lastUpdateWeather)
                }
            }
        }
    }
}
