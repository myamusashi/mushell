pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    anchors.fill: parent

    property bool isOpen: false
    property real sunriseProgress: calculateSunProgress()
    property string descriptions: ""

    margin: Appearance.margin.normal
    visible: opacity > 0
    color: Colours.m3Colors.m3Surface
    scale: isOpen ? 1.0 : 0.5
    opacity: isOpen ? 1.0 : 0.0
    transformOrigin: Item.Center

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
        onTriggered: root.sunriseProgress = root.calculateSunProgress()
    }

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Component {
        id: loadingIndicator

        LoadingIndicator {
            implicitWidth: 120
            implicitHeight: 120
            status: !Loader.Ready
        }
    }

    FileView {
        path: Qt.resolvedUrl("./Markdown/Sun.md")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.descriptions = text()
    }

    Loader {
        active: root.isOpen
        sourceComponent: Column {
            anchors.centerIn: parent

            Header {
                icon: Lucide.icon_sun
                title: "Sun"
                mouseArea.onClicked: root.isOpen = false
            }

            ClippingRectangle {
                color: Colours.m3Colors.m3SurfaceContainer
                radius: Appearance.rounding.normal
                implicitWidth: parent.width
                implicitHeight: parent.height * 0.3

                SunCanvas {
                    anchors.fill: parent
                    sunSize: 40

                    StyledRect {
                        anchors.bottom: parent.bottom
                        clip: true
                        color: Colours.withAlpha(Colours.m3Colors.m3Surface, 0.4)
                        implicitWidth: parent.width
                        implicitHeight: parent.height * 0.4
                        radius: 0

                        StyledRect {
                            anchors.top: parent.top
                            radius: 0
                            bottomLeftRadius: Appearance.rounding.normal
                            bottomRightRadius: bottomLeftRadius

                            implicitWidth: parent.width
                            implicitHeight: 1
                            color: Colours.m3Colors.m3OutlineVariant
                        }
                    }
                }
            }

            Column {
                width: parent.width
                height: parent.height * 0.7
                spacing: Appearance.spacing.large * 1.5
                Row {
                    width: parent.width
                    height: 40

                    Column {
                        width: parent.width / 2
                        spacing: 0
                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "Sunrise"
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.large
                        }
                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: Weather.sunRise
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                        }
                    }

                    Column {
                        width: parent.width / 2
                        spacing: 0

                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "Sunset"
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.large
                        }
                        StyledText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: Weather.sunSet
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                        }
                    }
                }

                WrapperRectangle {
                    border {
                        width: 1
                        color: Colours.m3Colors.m3Outline
                    }
                    margin: 20
                    radius: Appearance.rounding.normal
                    color: Colours.m3Colors.m3Surface
                    implicitWidth: parent.width
                    implicitHeight: description.contentHeight + 20

                    StyledText {
                        id: description

                        text: root.descriptions
                        color: Colours.m3Colors.m3OnSurface
                        textFormat: Text.MarkdownText
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }
            }
        }
    }

    component SunCanvas: Canvas {
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
            var t = root.sunriseProgress;

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
            target: root

            function onSunriseProgressChanged() {
                sunCanvas.requestPaint();
            }
        }
    }
}
