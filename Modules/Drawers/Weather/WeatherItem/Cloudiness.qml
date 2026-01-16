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
    shape: MaterialShape.Circle

    MaterialShape {
        anchors.centerIn: parent
        implicitWidth: 135
        implicitHeight: 135
        color: Colours.m3Colors.m3Primary
        opacity: 0.6
        shape: MaterialShape.Cookie6Sided
    }

    RowLayout {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 20
        }

        Icon {
            type: Icon.Lucide
            icon: Lucide.icon_cloud
            font.pixelSize: Appearance.fonts.size.large * 1.5
            color: Colours.m3Colors.m3OnSurface

            font.variableAxes: {
                "FILL": 10,
                "opsz": fontInfo.pixelSize,
                "wght": fontInfo.weight
            }
        }

        StyledText {
            text: "Cloudiness"
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
        }
    }

    StyledText {
        anchors.centerIn: parent
        text: Weather.cloudCover
        font.pixelSize: Appearance.fonts.size.extraLarge
        color: Colours.m3Colors.m3OnSurface
    }

    StyledText {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 20
        }

        text: "%"
        font.pixelSize: Appearance.fonts.size.large
        color: Colours.m3Colors.m3OnSurface
    }
}
