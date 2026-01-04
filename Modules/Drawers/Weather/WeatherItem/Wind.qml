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
        roundedPolygon: MaterialShapes.getArrow()
        onProgressChanged: requestPaint()

        rotation: {
            const direction = Weather.windDirection.toUpperCase();
            const directions = {
                "N": 0,
                "NNE": 22.5,
                "NE": 45,
                "ENE": 67.5,
                "E": 90,
                "ESE": 112.5,
                "SE": 135,
                "SSE": 157.5,
                "S": 180,
                "SSW": 202.5,
                "SW": 225,
                "WSW": 247.5,
                "W": 270,
                "WNW": 292.5,
                "NW": 315,
                "NNW": 337.5
            };
            return directions[direction] || 0;
        }

        Behavior on rotation {
            NAnim {}
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 20

        RowLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

            Icon {
                type: Icon.Material
                icon: "explore"
                font.pointSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface

                font.variableAxes: {
                    "FILL": 10,
                    "opsz": fontInfo.pixelSize,
                    "wght": fontInfo.weight
                }
            }

            StyledText {
                text: "Wind"
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurface
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            text: Weather.windDirection
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.weight: Font.Bold
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Layout.bottomMargin: 20
            text: Weather.windSpeed + " Km/h"
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            color: Colours.m3Colors.m3OnSurface
        }
    }
}
