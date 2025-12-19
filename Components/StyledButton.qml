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
    property int iconSize: Appearance.fonts.size.medium
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
    readonly property real normalWidth: contentRow.implicitWidth + 32

    signal clicked

    implicitWidth: normalWidth
    implicitHeight: buttonHeight

    ClippingRectangle {
        id: background

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: root.normalWidth * (mouseArea.pressed && root.enabled ? 1.1 : 1.0)
        implicitHeight: parent.height

        Behavior on implicitWidth {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        border.color: root.isButtonUseBorder ? root.buttonBorderColor : "transparent"
        border.width: root.isButtonUseBorder ? root.buttonBorderWidth : 0
		color: root.buttonColor
		radius: root.enabled ? Appearance.rounding.small : Appearance.rounding.full
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
            }
        ]

        transitions: [
            Transition {
                from: "enabled"
                to: "disabled"
                NAnim {
                    property: "radius"
                    duration: Appearance.animations.durations.emphasized
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            },
            Transition {
                from: "disabled"
                to: "enabled"
                NAnim {
                    property: "radius"
                    duration: Appearance.animations.durations.emphasized
                    easing.bezierCurve: Appearance.animations.curves.emphasized
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
                font.pointSize: root.iconSize > 0 ? root.iconSize : Appearance.fonts.size.large
                font.bold: true
                color: root.buttonTextColor
            }
        }
        Loader {
            active: root.buttonTitle !== ""
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: StyledText {
                text: root.buttonTitle
                font.pixelSize: Appearance.fonts.size.large
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
