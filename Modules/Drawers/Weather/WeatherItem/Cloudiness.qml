pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "../../../../Submodules/rounded-polygon-qmljs/material-shapes.js" as MaterialShapes

ShapeCanvas {
    color: Colours.m3Colors.m3SurfaceContainer
    roundedPolygon: MaterialShapes.getCircle()
    onProgressChanged: requestPaint()

    ShapeCanvas {
        anchors.centerIn: parent
        implicitWidth: 135
        implicitHeight: 135
        color: Colours.withAlpha(Colours.m3Colors.m3Primary, 0.6)
        roundedPolygon: MaterialShapes.getCookie6Sided()
        onProgressChanged: requestPaint()
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
            font.pointSize: Appearance.fonts.size.large
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
