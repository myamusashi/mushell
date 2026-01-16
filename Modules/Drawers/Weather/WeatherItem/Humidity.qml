pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

MaterialShape {
    id: shape

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square
    animationDuration: 0

    ClippingWrapperRectangle {
        anchors.fill: shape
        color: "transparent"
        radius: Appearance.rounding.large * 1.87

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
                type: Icon.Lucide
                icon: Lucide.icon_droplet
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }

            StyledText {
                text: "Humidity"
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
                text: "Dew point"
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurface
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component Wave: Canvas {
        id: waveCanvas

        property real fillPercentage: 0
        property color waveColor: Colours.withAlpha(Colours.m3Colors.m3Primary, 0.4)

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var fillHeight = height * (fillPercentage / 100);
            var waveY = height - fillHeight;

            ctx.fillStyle = waveColor;
            ctx.beginPath();

            ctx.moveTo(0, height);
            ctx.lineTo(0, waveY);

            var amplitude = 3;
            var wavelength = width / 5;
            var points = 100;

            for (var i = 0; i <= points; i++) {
                var x = (i / points) * width;
                var y = waveY + Math.sin((x / wavelength * Math.PI * 2)) * amplitude;
                ctx.lineTo(x, y);
            }

            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fill();
        }

        onFillPercentageChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }
}
