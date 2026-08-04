pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

RowLayout {
    id: root

    required property var island
    required property bool active

    implicitWidth: progressRowLayout.implicitWidth + 48
    implicitHeight: 44
    spacing: Appearance.spacing.normal

    RowLayout {
        id: progressRowLayout

        spacing: Appearance.spacing.normal
        visible: root.active

        Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            color: "transparent"

            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
                running: root.active
            }

            Shape {
                anchors.centerIn: parent
                height: 16
                width: 16
                preferredRendererType: Shape.CurveRenderer
                visible: root.active

                ShapePath {
                    strokeColor: Colours.m3Colors.m3Primary
                    strokeWidth: 3
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 8
                        centerY: 8
                        radiusX: 5
                        radiusY: 5
                        startAngle: 0
                        sweepAngle: 280
                    }
                }
            }
        }

        StyledText {
            text: qsTr("Sending...")
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            implicitWidth: cancelLabel.implicitWidth + 16
            implicitHeight: 28
            radius: Appearance.rounding.small
            color: cancelMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Error, 0.12) : "transparent"

            StyledText {
                id: cancelLabel

                anchors.centerIn: parent
                text: qsTr("Cancel")
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3Error
            }

            MArea {
                id: cancelMouseArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.island.cancelTransfer()
            }
        }
    }
}
