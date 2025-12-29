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

    color: "#1a1a1a"
    roundedPolygon: MaterialShapes.getSquare()
    property real sunriseProgress: calculateSunProgress()
    clip: true

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

    Sun {}

    RowLayout {
        implicitWidth: parent.width
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 5
        }

        MaterialIcon {
            icon: "wb_twilight"
            font.pointSize: Appearance.fonts.size.large * 1.2
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
        height: childrenRect.height

        ColumnLayout {
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
                color: Colours.withAlpha(Colours.m3Colors.m3Surface, 0.5)

                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.margins: 0
                    spacing: 0

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: childrenRect.width
                        implicitHeight: childrenRect.height

                        MaterialIcon {
                            id: sunriseIcon

                            icon: "vertical_align_top"
                            font.pointSize: Appearance.fonts.size.normal
                            color: Colours.m3Colors.m3OnSurface
                        }
                        StyledText {
                            anchors.left: sunriseIcon.right
                            anchors.leftMargin: 4
                            anchors.verticalCenter: sunriseIcon.verticalCenter
                            text: TimeAgo.convertTo12Hour(Weather.sunRise)
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurface
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: childrenRect.width
                        implicitHeight: childrenRect.height

                        MaterialIcon {
                            id: sunsetIcon

                            icon: "vertical_align_bottom"
                            font.pointSize: Appearance.fonts.size.normal
                            color: Colours.m3Colors.m3OnSurface
                        }
                        StyledText {
                            anchors.left: sunsetIcon.right
                            anchors.leftMargin: 4
                            anchors.verticalCenter: sunsetIcon.verticalCenter
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

        anchors.fill: parent
        property color hillColor: Colours.m3Colors.m3Primary
        property color sunColor: Colours.m3Colors.m3Yellow
        property real sunSize: 20
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            // Get the parent's morph and create clipping path
            var morph = canvas.morph;
            if (!morph)
                return;
            var cubics = morph.asCubics(canvas.progress);
            if (cubics.length === 0)
                return;

            var size = Math.min(width, height);
            var offsetX = width / 2 - size / 2;
            var offsetY = height / 2 - size / 2;

            ctx.save();

            // Apply clipping path
            ctx.translate(offsetX, offsetY);
            if (canvas.polygonIsNormalized)
                ctx.scale(size, size);
            ctx.beginPath();
            ctx.moveTo(cubics[0].anchor0X, cubics[0].anchor0Y);
            for (var i = 0; i < cubics.length; i++) {
                var cubic = cubics[i];
                ctx.bezierCurveTo(cubic.control0X, cubic.control0Y, cubic.control1X, cubic.control1Y, cubic.anchor1X, cubic.anchor1Y);
            }
            ctx.closePath();
            ctx.clip();

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

            function onProgressChanged() {
                sunCanvas.requestPaint();
			}

            function onSunriseProgressChanged() {
                sunCanvas.requestPaint();
            }
        }
    }
}
