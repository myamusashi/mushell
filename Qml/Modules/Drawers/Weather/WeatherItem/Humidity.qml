pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell.Widgets
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MaterialShape {
    id: shape

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square
    animationDuration: 0

    ClippingWrapperRectangle {
        anchors.fill: shape
        color: "transparent"
        radius: Appearance.rounding.large * 1.8

        Wave {
            fillPercentage: Weather.humidity
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.normal
        z: 2

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop | Qt.AlignCenter
            Layout.topMargin: 5
            spacing: 0

            Icon {
                type: Icon.Material
                icon: "water_drop"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }

            StyledText {
                text: qsTr("Humidity")
                color: Colours.m3Colors.m3OnSurface
                font.weight: Font.Bold
                font.pixelSize: Appearance.fonts.size.normal
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            text: Weather.humidity + "%"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
            font.weight: Font.Bold
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom | Qt.AlignCenter
            Layout.bottomMargin: 30
            spacing: Appearance.spacing.small

            implicitHeight: 30
            implicitWidth: 30

            MaterialShape {
                implicitWidth: 30
                implicitHeight: 30
                color: Colours.m3Colors.m3Primary
                shape: MaterialShape.Circle
                animationDuration: 0

                StyledText {
                    anchors.centerIn: parent
                    text: Weather.dewPoint.toFixed(0) + "°"
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    color: Colours.m3Colors.m3Surface
                }
            }

            StyledText {
                text: qsTr("Dew point")
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurface
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component Wave: Shape {
        id: waveShape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        property alias fillPercentage: waveGeo.fillPercentage
        property color waveColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.4)

        ShapePath {
            strokeColor: "transparent"
            fillColor: waveShape.waveColor

            PathSvg {
                path: waveGeo.buildPath()
            }
        }

        QtObject {
            id: waveGeo

            readonly property real widthPx: waveShape.parent.width
            readonly property real heightPx: waveShape.parent.height

            property real fillPercentage: 0
            property real fillHeight: heightPx * (fillPercentage / 100)
            property real waveY: heightPx - fillHeight
            property real amplitude: 3
            property real wavelength: widthPx / 5

            function buildPath() {
                if (fillHeight <= 0)
                    return "M 0 0";

                var points = 100;
                var pathData = "M 0 " + heightPx + " L 0 " + waveY;

                for (var i = 0; i <= points; i++) {
                    var x = (i / points) * widthPx;
                    var y = waveY + Math.sin((x / wavelength) * Math.PI * 2) * amplitude;
                    pathData += " L " + x + " " + y;
                }

                pathData += " L " + widthPx + " " + heightPx + " Z";
                return pathData;
            }
        }
    }
}
