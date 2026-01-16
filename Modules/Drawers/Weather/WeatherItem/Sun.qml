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
    id: canvas

    property real sunriseProgress: calculateSunProgress()

    color: "#1a1a1a"
    shape: MaterialShape.Square
    animationDuration: 0

    function calculateSunProgress() {
        var now = new Date();
        var currentMinutes = now.getHours() * 60 + now.getMinutes();

        var sunriseParts = Weather.sunRise.split(":");
        var sunriseMinutes = parseInt(sunriseParts[0]) * 60 + parseInt(sunriseParts[1]);

        var sunsetParts = Weather.sunSet.split(":");
        var sunsetMinutes = parseInt(sunsetParts[0]) * 60 + parseInt(sunsetParts[1]);

        if (currentMinutes < sunriseMinutes) {
            return 0;
        } else if (currentMinutes > sunsetMinutes) {
            return 1;
        } else {
            var dayLength = sunsetMinutes - sunriseMinutes;
            var elapsed = currentMinutes - sunriseMinutes;
            return elapsed / dayLength;
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: canvas.sunriseProgress = canvas.calculateSunProgress()
    }

    ClippingWrapperRectangle {
        anchors.fill: parent
        color: "transparent"
        bottomLeftRadius: Appearance.rounding.large * 1.87
        bottomRightRadius: bottomLeftRadius
        Sun {}
    }

    RowLayout {
        implicitWidth: parent.width
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 5
        }

        Icon {
            type: Icon.Material
            icon: "wb_twilight"
            font.pixelSize: Appearance.fonts.size.large * 1.5
            color: Colours.m3Colors.m3OnSurface

            font.variableAxes: {
                "FILL": 10,
                "opsz": fontInfo.pixelSize,
                "wght": fontInfo.weight
            }
        }

        StyledText {
            text: "Sun"
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurface
        }
    }

    Item {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        implicitHeight: contentLayout.implicitHeight

        ColumnLayout {
            id: contentLayout

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            spacing: 1

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colours.m3Colors.m3OutlineVariant
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 60
                radius: 0
                bottomLeftRadius: Appearance.rounding.full
                bottomRightRadius: bottomLeftRadius
                color: Colours.withAlpha(Colours.m3Colors.m3Surface, 0.5)

                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.margins: 0
                    spacing: 0

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.small

                        Icon {
                            type: Icon.Material
                            icon: "vertical_align_top"
                            font.pixelSize: Appearance.fonts.size.normal
                            color: Colours.m3Colors.m3OnSurface
                        }

                        StyledText {
                            text: TimeAgo.convertTo12Hour(Weather.sunRise)
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurface
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.small

                        Icon {
                            type: Icon.Material
                            icon: "vertical_align_bottom"
                            font.pixelSize: Appearance.fonts.size.normal
                            color: Colours.m3Colors.m3OnSurface
                        }

                        StyledText {
                            text: TimeAgo.convertTo12Hour(Weather.sunSet)
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurface
                        }
                    }
                }
            }
        }
    }

    component Sun: Canvas {
        id: sunCanvas

        property color hillColor: Colours.m3Colors.m3Primary
        property color sunColor: Colours.m3Colors.m3Yellow
        property real sunSize: 20

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var size = Math.min(width, height);
            var offsetX = width / 2 - size / 2;
            var offsetY = height / 2 - size / 2;

            ctx.save();

            // Reset transform to draw in canvas coordinates
            ctx.setTransform(1, 0, 0, 1, 0, 0);

            // Draw hill - simple smooth curve at bottom
            var hillHeight = height * 0.6;
            var hillBaseY = height - hillHeight;

            // Define hill curve control points
            var startX = 0;
            var startY = hillBaseY + hillHeight * 0.3;
            var cp1X = width * 0.3;
            var cp1Y = hillBaseY - hillHeight * 0.1;
            var cp2X = width * 0.7;
            var cp2Y = hillBaseY - hillHeight * 0.1;
            var endX = width;
            var endY = hillBaseY + hillHeight * 0.3;

            ctx.fillStyle = hillColor;
            ctx.beginPath();
            ctx.moveTo(0, height);
            ctx.lineTo(startX, startY);

            // Smooth bezier curve for hill
            ctx.bezierCurveTo(cp1X, cp1Y, cp2X, cp2Y, endX, endY);

            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fill();

            // Calculate sun position on the bezier curve
            var t = canvas.sunriseProgress;

            // Cubic bezier formula: B(t) = (1-t)³P0 + 3(1-t)²tP1 + 3(1-t)t²P2 + t³P3
            var oneMinusT = 1 - t;
            var sunX = Math.pow(oneMinusT, 3) * startX + 3 * Math.pow(oneMinusT, 2) * t * cp1X + 3 * oneMinusT * Math.pow(t, 2) * cp2X + Math.pow(t, 3) * endX;

            var sunY = Math.pow(oneMinusT, 3) * startY + 3 * Math.pow(oneMinusT, 2) * t * cp1Y + 3 * oneMinusT * Math.pow(t, 2) * cp2Y + Math.pow(t, 3) * endY;

            // Draw sun
            ctx.fillStyle = sunColor;
            ctx.strokeStyle = sunColor;
            ctx.lineWidth = 2;

            ctx.beginPath();
            ctx.arc(sunX, sunY, sunSize / 2, 0, 2 * Math.PI);
            ctx.fill();
            ctx.stroke();

            ctx.restore();
        }

        Connections {
            target: canvas

            function onSunriseProgressChanged() {
                sunCanvas.requestPaint();
            }
        }
    }
}
