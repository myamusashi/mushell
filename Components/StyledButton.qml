pragma ComponentBehavior: Bound

import QtQuick

import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    property string buttonTitle
    property string iconButton: ""
    property int iconSize: Appearance.fonts.medium
    property color buttonColor: Colours.m3Colors.m3Primary
    property color buttonTextColor: Colours.m3Colors.m3OnBackground
    property color buttonBorderColor: Colours.m3Colors.m3Outline
    property int buttonBorderWidth: 2
    property int buttonHeight: 40
    property int iconTextSpacing: 8
    property bool enabled: true
    property bool isButtonUseBorder: false
    property real backgroundRounding: 0
    property int baseWidth: implicitWidth
    property alias mArea: mouseArea
    property alias bg: background

    signal clicked

    implicitWidth: contentRow.implicitWidth + 32
    implicitHeight: buttonHeight

    ClippingRectangle {
        id: background

        anchors.fill: parent
        border.color: root.isButtonUseBorder ? root.buttonBorderColor : "transparent"
        border.width: root.isButtonUseBorder ? root.buttonBorderWidth : 0
        radius: Appearance.rounding.full
        color: root.buttonColor
        opacity: root.enabled ? (mouseArea.pressed ? 0.8 : (mouseArea.containsMouse ? 0.9 : 1.0)) : 0.5

        states: [
            State {
                name: "enabled"
                when: root.enabled === true && !mouseArea.pressed
                PropertyChanges {
                    target: background
                    radius: Appearance.rounding.small
                }
            },
            State {
                name: "disabled"
                when: root.enabled === false
                PropertyChanges {
                    target: background
                    radius: Appearance.rounding.full
                }
            },
            State {
                name: "pressed"
                when: mouseArea.pressed && root.enabled
                PropertyChanges {
                    target: background
                    radius: Appearance.rounding.small
                }
                PropertyChanges {
                    target: root
                    width: root.implicitWidth * 1.05
                }
            }
        ]

        transitions: [
            Transition {
                from: "enabled"
                to: "disabled"
                NAnim {
                    property: "radius"
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                    easing.type: Easing.Linear
                }
            },
            Transition {
                from: "disabled"
                to: "enabled"
                NAnim {
                    property: "radius"
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                    easing.type: Easing.Linear
                }
            },
            Transition {
                to: "pressed"
                NAnim {
                    property: "width"
                    duration: Appearance.animations.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
            },
            Transition {
                from: "pressed"
                NAnim {
                    property: "width"
                    duration: Appearance.animations.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
            }
        ]
    }

    Row {
        id: contentRow

        spacing: root.iconTextSpacing
        anchors.centerIn: parent
        opacity: root.enabled ? 1.0 : 0.5
        Loader {
            active: root.iconButton !== ""
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: MaterialIcon {
                icon: root.iconButton
                font.pointSize: root.iconSize > 0 ? root.iconSize : Appearance.fonts.large
                font.bold: true
                color: root.buttonTextColor
            }
        }
        Loader {
            active: root.buttonTitle !== ""
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: StyledText {
                text: root.buttonTitle
                font.pixelSize: Appearance.fonts.large
                font.weight: Font.Medium
                color: root.buttonTextColor
            }
        }
    }
    MArea {
        id: mouseArea

        anchors.fill: parent
        layerColor: "transparent"
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
