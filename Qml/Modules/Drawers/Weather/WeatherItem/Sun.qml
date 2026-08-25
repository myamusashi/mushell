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
    id: canvas

    property real sunriseProgress: calculateSunProgress()

    color: Colours.m3Colors.m3SurfaceContainerHighest
    shape: MaterialShape.Square
    animationDuration: 0

    function calculateSunProgress(): double {
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
        bottomLeftRadius: Appearance.rounding.large * 1.23
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
            text: qsTr("Sun")
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
                color: Qt.alpha(Colours.m3Colors.m3Surface, 0.5)

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

    component Sun: Shape {
        id: sunShape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        property color hillColor: Colours.m3Colors.m3Primary
        property color sunColor: Colours.m3Colors.m3Yellow
        property real sunSize: 20

        // Hill
        ShapePath {
            strokeColor: "transparent"
            fillColor: sunShape.hillColor

            startX: 0
            startY: sunShape.height

            PathLine {
                x: geometry.hillStartX
                y: geometry.hillStartY
            }
            PathCubic {
                control1X: geometry.hillControlPoint1X
                control1Y: geometry.hillControlPoint1Y
                control2X: geometry.hillControlPoint2X
                control2Y: geometry.hillControlPoint2Y
                x: geometry.hillEndX
                y: geometry.hillEndY
            }
            PathLine {
                x: sunShape.width
                y: sunShape.height
            }
            PathLine {
                x: 0
                y: sunShape.height
            }
        }

        // Sun
        ShapePath {
            strokeColor: sunShape.sunColor
            strokeWidth: 2
            fillColor: sunShape.sunColor

            PathAngleArc {
                centerX: geometry.sunX
                centerY: geometry.sunY
                radiusX: sunShape.sunSize / 2
                radiusY: sunShape.sunSize / 2
                startAngle: 0
                sweepAngle: 360
            }
        }

        QtObject {
            id: geometry

            // foking binding loop
            readonly property real widthPx: sunShape.parent.width
            readonly property real heightPx: sunShape.parent.height

            property real hillHeight: heightPx * 0.6
            property real hillBaseY: heightPx - hillHeight
            property real hillStartX: 0
            property real hillStartY: hillBaseY + hillHeight * 0.3
            property real hillControlPoint1X: widthPx * 0.3
            property real hillControlPoint1Y: hillBaseY - hillHeight * 0.1
            property real hillControlPoint2X: widthPx * 0.7
            property real hillControlPoint2Y: hillBaseY - hillHeight * 0.1
            property real hillEndX: widthPx
            property real hillEndY: hillBaseY + hillHeight * 0.3

            property real progress: canvas.sunriseProgress
            property real oneMinusProgress: 1 - progress
            property real sunX: Math.pow(oneMinusProgress, 3) * hillStartX + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1X + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2X + Math.pow(progress, 3) * hillEndX
            property real sunY: Math.pow(oneMinusProgress, 3) * hillStartY + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1Y + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2Y + Math.pow(progress, 3) * hillEndY
        }
    }
}
