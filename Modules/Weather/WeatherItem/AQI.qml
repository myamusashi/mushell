pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "../../../Submodules/rounded-polygon-qmljs/material-shapes.js" as MaterialShapes

ShapeCanvas {
	id: canvas

    color: Colours.m3Colors.m3SurfaceContainer
    clip: true
    roundedPolygon: MaterialShapes.getSquare()
    onProgressChanged: requestPaint()

    property int aqi: 90
    property var aqiCategories: [
        {
            max: 50,
            label: "Good",
            color: "#4CAF50"
        },
        {
            max: 100,
            label: "Fair",
            color: "#FFEB3B"
        },
        {
            max: 150,
            label: "Moderate",
            color: "#FF9800"
        },
        {
            max: 200,
            label: "Poor",
            color: "#F44336"
        },
        {
            max: 300,
            label: "Very Poor",
            color: "#9C27B0"
        },
        {
            max: 500,
            label: "Hazardous",
            color: "#8B0000"
        }
    ]

    function getAQICategory(value) {
        for (var i = 0; i < aqiCategories.length; i++) {
            if (value <= aqiCategories[i].max) {
                return aqiCategories[i];
            }
        }
        return aqiCategories[aqiCategories.length - 1];
    }

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: 20
            leftMargin: 20
            rightMargin: 20
            bottomMargin: 20
		}

        spacing: Appearance.spacing.small

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            MaterialIcon {
                icon: "airwave"
                font.pointSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurface
            }
            StyledText {
                text: "AQI"
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurface
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignRight
            text: canvas.aqi
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.weight: Font.Bold
            color: Colours.m3Colors.m3OnSurface
        }

        Item {
            Layout.fillHeight: true
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            Layout.bottomMargin: 8

            StyledRect {
				implicitWidth: parent.width
				implicitHeight: 5
                radius: Appearance.rounding.small
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "#4CAF50"
                    }
                    GradientStop {
                        position: 0.2
                        color: "#FFEB3B"
                    }
                    GradientStop {
                        position: 0.4
                        color: "#FF9800"
                    }
                    GradientStop {
                        position: 0.6
                        color: "#F44336"
                    }
                    GradientStop {
                        position: 0.8
                        color: "#9C27B0"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#8B0000"
                    }
                }
            }

            StyledRect {
                width: 10
                height: 10
                radius: Appearance.rounding.normal
                color: Colours.m3Colors.m3Surface
                border.width: 1
                border.color: Colours.m3Colors.m3OnSurface

                x: Math.min(Math.max(0, (canvas.aqi / 500) * parent.width - width / 2), parent.width - width)
                y: parent.height / 2 - height / 2

                Behavior on x {
                    NAnim {
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignRight
            text: canvas.getAQICategory(canvas.aqi).label
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnSurface
		}
    }
}
