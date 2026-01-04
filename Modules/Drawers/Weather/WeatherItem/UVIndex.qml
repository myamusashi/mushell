pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "../../../../Submodules/rounded-polygon-qmljs/material-shapes.js" as MaterialShapes

ShapeCanvas {
    id: canvas

    property int uvIndex: Weather.uvIndex
    property var uvColors: ["#4CAF50"  // Low (0-2) - Green
        , "#FFEB3B"  // Moderate (3-5) - Yellow
        , "#FF9800"  // High (6-7) - Orange
        , "#F44336"  // Very High (8-10) - Red
        , "#9C27B0"   // Extreme (11+) - Purple
    ]
    property var uvLabels: ["Low", "Moderate", "High", "Very High", "Extreme"]

    color: Colours.m3Colors.m3SurfaceContainer
    roundedPolygon: MaterialShapes.getCookie12Sided()
    onProgressChanged: requestPaint()

    function getUVCategory(index) {
        if (index <= 2)
            return 0;
        if (index <= 5)
            return 1;
        if (index <= 7)
            return 2;
        if (index <= 10)
            return 3;
        return 4;
    }

    RowLayout {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 20
        }

        Icon {
            type: Icon.Material
            icon: "sunny"
            font.pointSize: Appearance.fonts.size.large * 1.2
            color: Colours.m3Colors.m3OnSurface
            font.variableAxes: {
                "FILL": 10,
                "opsz": fontInfo.pixelSize,
                "wght": fontInfo.weight
            }
        }

        StyledText {
            text: "UV index"
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: canvas.uvIndex
            font.pixelSize: Appearance.fonts.size.large * 1.5
            font.weight: Font.Bold
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: canvas.uvLabels[canvas.getUVCategory(canvas.uvIndex)]
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurface
        }
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: 5

            StyledRect {
                id: indicator

                required property int index
                property real angle: 150 - (index * 30)
                property real distance: Math.min(parent.width, parent.height) * 0.38
                property int currentCategory: canvas.getUVCategory(canvas.uvIndex)

                width: 18
                height: 18
                radius: Appearance.rounding.normal
                color: index === currentCategory ? canvas.uvColors[index] : Colours.withAlpha(canvas.uvColors[index], 0.3)

                x: parent.width / 2 + Math.cos(angle * Math.PI / 180) * distance - width / 2
                y: parent.height / 2 + Math.sin(angle * Math.PI / 180) * distance - height / 2

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }
}
