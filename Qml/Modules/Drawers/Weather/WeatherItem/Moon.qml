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

    property real moonriseProgress: calculateMoonProgress()

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square

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

    ClippingWrapperRectangle {
        anchors.fill: parent
        color: "transparent"
        bottomLeftRadius: Appearance.rounding.large * 1.23
        bottomRightRadius: bottomLeftRadius
        Moon {}
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
            icon: "bedtime"
            font.pixelSize: Appearance.fonts.size.large * 1.5
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            text: qsTr("Moon")
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurface
        }
    }

    WrapperItem {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        implicitHeight: contentLayout.implicitHeight

        ColumnLayout {
            id: contentLayout

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
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Appearance.spacing.small

                        Icon {
                            type: Icon.Material
                            icon: "vertical_align_top"
                            font.pixelSize: Appearance.fonts.size.normal
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
                            font.pixelSize: Appearance.fonts.size.normal
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

    component Moon: Shape {
        id: moonShape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        property color hillColor: Colours.m3Colors.m3Primary
        property color moonColor: Colours.m3Colors.m3OnSurfaceVariant
        property real moonSize: 20

        // Hill
        ShapePath {
            strokeColor: "transparent"
            fillColor: moonShape.hillColor

            startX: 0
            startY: moonGeo.heightPx

            PathLine {
                x: moonGeo.hillStartX
                y: moonGeo.hillStartY
            }
            PathCubic {
                control1X: moonGeo.hillControlPoint1X
                control1Y: moonGeo.hillControlPoint1Y
                control2X: moonGeo.hillControlPoint2X
                control2Y: moonGeo.hillControlPoint2Y
                x: moonGeo.hillEndX
                y: moonGeo.hillEndY
            }
            PathLine {
                x: moonGeo.widthPx
                y: moonGeo.heightPx
            }
            PathLine {
                x: 0
                y: moonGeo.heightPx
            }
        }

        // Moon
        ShapePath {
            strokeColor: moonShape.moonColor
            strokeWidth: 2
            fillColor: moonShape.moonColor

            PathAngleArc {
                centerX: moonGeo.moonX
                centerY: moonGeo.moonY
                radiusX: moonShape.moonSize / 2
                radiusY: moonShape.moonSize / 2
                startAngle: 0
                sweepAngle: 360
            }
        }

        QtObject {
            id: moonGeo

            readonly property real widthPx: moonShape.parent.width
            readonly property real heightPx: moonShape.parent.height

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

            property real progress: canvas.moonriseProgress
            property real oneMinusProgress: 1 - progress
            property real moonX: Math.pow(oneMinusProgress, 3) * hillStartX + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1X + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2X + Math.pow(progress, 3) * hillEndX
            property real moonY: Math.pow(oneMinusProgress, 3) * hillStartY + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1Y + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2Y + Math.pow(progress, 3) * hillEndY
        }
    }
}
