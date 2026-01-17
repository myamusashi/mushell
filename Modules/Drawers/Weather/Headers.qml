import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Appearance.spacing.normal

    Progress {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        condition: Weather.isInitialLoading || Weather.isRefreshing
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: Appearance.rounding.full
        color: Colours.m3Colors.m3SurfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.margin.normal
            anchors.rightMargin: Appearance.margin.normal
            spacing: Appearance.spacing.small

            Icon {
                type: Icon.Lucide
                icon: Lucide.icon_map_pin
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
            }
            StyledText {
                text: Weather.locationName + ", " + Weather.locationRegion + ", " + Weather.locationCountry
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
            }

            Item {
                Layout.fillWidth: true
            }

            Icon {
                Layout.alignment: Qt.AlignRight
                icon: "refresh"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Weather.canRefresh ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                    onClicked: Weather.refresh()
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
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
                    font.weight: Font.DemiBold
                }

                Icon {
                    type: Icon.Weather
                    icon: Weather.weatherIcon
                    font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
                    color: Colours.m3Colors.m3Primary
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
                spacing: Appearance.spacing.normal

                Repeater {
                    model: [
                        {
                            text: Weather.tempMax + "°",
                            icon: Lucide.icon_arrow_up
                        },
                        {
                            text: Weather.tempMin + "°",
                            icon: Lucide.icon_arrow_down
                        }
                    ]

                    delegate: RowLayout {
                        required property var modelData

                        spacing: Appearance.spacing.small

                        Icon {
                            type: Icon.Lucide
                            icon: parent.modelData.icon
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                        }

                        StyledText {
                            text: parent.modelData.text
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.DemiBold
                        }
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

                Icon {
                    type: Icon.Material
                    icon: "update"
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurface
                }

                StyledText {
                    text: TimeAgo.formatTimestampRelative(parseInt(Weather.lastUpdateWeather))
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
