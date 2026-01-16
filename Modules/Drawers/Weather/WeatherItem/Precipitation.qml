pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

MaterialShape {
    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square

    ColumnLayout {
        anchors {
            fill: parent
            margins: 20
        }

        RowLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

            Icon {
                type: Icon.Lucide
                icon: Lucide.icon_cloud_rain
                font.pixelSize: Appearance.fonts.size.large * 1.5
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                text: "Precipitation"
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurface
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 0

            StyledText {
                text: Weather.precipitationDaily
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 5
                text: "mm"
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurfaceVariant
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.maximumWidth: 70
                text: "Total rain for the day"
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurface
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }

            Icon {
                type: Icon.Lucide
                icon: Lucide.icon_cloud_rain_wind
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurface
            }
        }
    }
}
