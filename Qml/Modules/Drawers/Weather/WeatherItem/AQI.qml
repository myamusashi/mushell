pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MaterialShape {
    id: canvas

    property int aqi: Weather.usAQI
    property var aqiCategories: [
        {
            max: 50,
            label: qsTr("Good"),
            color: Colours.m3Colors.m3Green
        },
        {
            max: 100,
            label: qsTr("Fair"),
            color: Colours.m3Colors.m3Yellow
        },
        {
            max: 150,
            label: qsTr("Moderate"),
            color: Colours.m3Colors.m3Orange
        },
        {
            max: 200,
            label: qsTr("Poor"),
            color: Colours.m3Colors.m3Red
        },
        {
            max: 300,
            label: qsTr("Very Poor"),
            color: Colours.m3Colors.m3Purple
        },
        {
            max: 500,
            label: qsTr("Hazardous"),
            color: Colours.m3Colors.m3Maroon
        }
    ]

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square

    function getAQICategory(value) {
        for (var i = 0; i < aqiCategories.length; i++)
            if (value <= aqiCategories[i].max)
                return aqiCategories[i];

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

            Icon {
                type: Icon.Material
                icon: "waves"
                font.pixelSize: Appearance.fonts.size.large * 1.5
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                text: qsTr("AQI")
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
                        color: Colours.m3Colors.m3Green
                    }
                    GradientStop {
                        position: 0.2
                        color: Colours.m3Colors.m3Yellow
                    }
                    GradientStop {
                        position: 0.4
                        color: Colours.m3Colors.m3Orange
                    }
                    GradientStop {
                        position: 0.6
                        color: Colours.m3Colors.m3Red
                    }
                    GradientStop {
                        position: 0.8
                        color: Colours.m3Colors.m3Purple
                    }
                    GradientStop {
                        position: 1.0
                        color: Colours.m3Colors.m3Maroon
                    }
                }
            }

            StyledRect {
                implicitWidth: 15
                implicitHeight: 15
                radius: implicitWidth / 2
                color: Colours.m3Colors.m3Surface
                border.width: 2
                border.color: Colours.m3Colors.m3OnSurface
                x: {
                    var position = 0;
                    var value = canvas.aqi;

                    if (value <= 50) {
                        position = (value / 50) * 0.2; // 0-20% of gradient
                    } else if (value <= 100) {
                        position = 0.2 + ((value - 50) / 50) * 0.2; // 20-40%
                    } else if (value <= 150) {
                        position = 0.4 + ((value - 100) / 50) * 0.2; // 40-60%
                    } else if (value <= 200) {
                        position = 0.6 + ((value - 150) / 50) * 0.2; // 60-80%
                    } else if (value <= 300) {
                        position = 0.8 + ((value - 200) / 100) * 0.2; // 80-100%
                    } else {
                        position = Math.min(1.0, 0.8 + ((value - 300) / 200) * 0.2);
                    }

                    return Math.min(Math.max(0, position * parent.width - width / 2), parent.width - width);
                }
                y: parent.height / 2 - height / 2
                Behavior on x {
                    NAnim {}
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
