pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

MaterialShape {
    id: canvas

    property real pressure: Weather.pressure
    property real minPressure: 0
    property real maxPressure: 2000

    animationDuration: 0
    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Circle

    Pressure {
        ColumnLayout {
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 30
            }

            RowLayout {
                Icon {
                    type: Icon.Material
                    icon: "vertical_align_center"
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                    font.weight: Font.DemiBold
                    color: Colours.m3Colors.m3OnSurface
                }

                StyledText {
                    text: "Pressure"
                    font.weight: Font.DemiBold
                    color: Colours.m3Colors.m3OnSurface
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter

                text: Weather.pressure
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.weight: Font.Bold
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter

                text: "hPa"
                font.pixelSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface
            }
        }
    }

    component Pressure: Canvas {
        id: gaugeCanvas

        anchors.fill: parent
        anchors.margins: 3

        property real normalizedValue: (canvas.pressure - canvas.minPressure) / (canvas.maxPressure - canvas.minPressure)
        property color trackColor: Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.2)
        property color activeColor: Colours.m3Colors.m3Primary

        onNormalizedValueChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var centerX = width / 2;
            var centerY = height / 2;
            var radius = Math.min(width, height) / 2 - 10;
            var lineWidth = 9;

            // Arc spans from 135° to 45° (270° total, leaving bottom 90° open)
            var startAngle = Math.PI * 0.75; // 135°
            var endAngle = Math.PI * 2.25; // 405° = 45°
            var totalAngle = endAngle - startAngle;

            ctx.lineCap = "round";
            ctx.lineWidth = lineWidth;

            // background track
            ctx.strokeStyle = trackColor;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
            ctx.stroke();

            // active progress
            var progressAngle = startAngle + (totalAngle * normalizedValue);
            ctx.strokeStyle = activeColor;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, startAngle, progressAngle, false);
            ctx.stroke();
        }
    }
}
