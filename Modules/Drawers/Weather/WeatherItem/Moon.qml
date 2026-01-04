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

    property real moonriseProgress: calculateMoonProgress()

    color: Colours.m3Colors.m3SurfaceContainer
    clip: true
    roundedPolygon: MaterialShapes.getSquare()
    onProgressChanged: requestPaint()

    function calculateMoonProgress() {
        var now = new Date();
        var currentMinutes = now.getHours() * 60 + now.getMinutes();

        var moonriseParts = Weather.moonRise.split(":");
        var moonriseMinutes = parseInt(moonriseParts[0]) * 60 + parseInt(moonriseParts[1]);

        var moonsetParts = Weather.moonSet.split(":");
        var moonsetMinutes = parseInt(moonsetParts[0]) * 60 + parseInt(moonsetParts[1]);

        if (currentMinutes < moonriseMinutes) {
            return 0;
        } else if (currentMinutes > moonsetMinutes) {
            return 1;
        } else {
            var dayLength = moonsetMinutes - moonriseMinutes;
            var elapsed = currentMinutes - moonriseMinutes;
            return elapsed / dayLength;
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: canvas.moonriseProgress = canvas.calculateMoonProgress()
    }

    Moon {}

    RowLayout {
        implicitWidth: parent.width
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 5
        }

        Icon {
            type: Icon.Lucide
            icon: Lucide.icon_moon
            font.pointSize: Appearance.fonts.size.large * 1.2
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            text: "Moon"
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
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Appearance.spacing.small

                        Icon {
                            type: Icon.Material
                            icon: "vertical_align_top"
                            font.pointSize: Appearance.fonts.size.normal
                            color: Colours.m3Colors.m3OnSurface
                        }

                        StyledText {
                            text: TimeAgo.convertTo12Hour(Weather.moonRise)
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurface
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: childrenRect.width
                        implicitHeight: childrenRect.height

                        Icon {
                            id: moonsetIcon

                            type: Icon.Material
                            icon: "vertical_align_bottom"
                            font.pointSize: Appearance.fonts.size.normal
                            color: Colours.m3Colors.m3OnSurface
                        }
                        StyledText {
                            anchors {
                                left: moonsetIcon.right
                                leftMargin: 4
                                verticalCenter: moonsetIcon.verticalCenter
                            }
                            text: TimeAgo.convertTo12Hour(Weather.moonSet)
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurface
                        }
                    }
                }
            }
        }
    }

    component Moon: Canvas {
        id: moonCanvas

        property color hillColor: Colours.m3Colors.m3Primary
        property color moonColor: Colours.m3Colors.m3OnSurfaceVariant
        property real moonSize: 20

        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

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

            ctx.setTransform(1, 0, 0, 1, 0, 0);

            var hillHeight = height * 0.6;
            var hillBaseY = height - hillHeight;

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

            ctx.bezierCurveTo(cp1X, cp1Y, cp2X, cp2Y, endX, endY);

            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fill();

            var t = canvas.moonriseProgress;

            // Cubic bezier formula: B(t) = (1-t)³P0 + 3(1-t)²tP1 + 3(1-t)t²P2 + t³P3
            var oneMinusT = 1 - t;
            var moonX = Math.pow(oneMinusT, 3) * startX + 3 * Math.pow(oneMinusT, 2) * t * cp1X + 3 * oneMinusT * Math.pow(t, 2) * cp2X + Math.pow(t, 3) * endX;
            var moonY = Math.pow(oneMinusT, 3) * startY + 3 * Math.pow(oneMinusT, 2) * t * cp1Y + 3 * oneMinusT * Math.pow(t, 2) * cp2Y + Math.pow(t, 3) * endY;

            // Draw moon
            ctx.fillStyle = moonColor;
            ctx.strokeStyle = moonColor;
            ctx.lineWidth = 2;

            ctx.beginPath();
            ctx.arc(moonX, moonY, moonSize / 2, 0, 2 * Math.PI);
            ctx.fill();
            ctx.stroke();

            ctx.restore();
        }
        Connections {
            target: canvas

            function onProgressChanged() {
                moonCanvas.requestPaint();
            }

            function onMoonriseProgressChanged() {
                moonCanvas.requestPaint();
            }
        }
    }
}
