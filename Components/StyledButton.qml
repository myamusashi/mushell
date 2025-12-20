pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    property alias mArea: mouseArea
    property alias bg: background
    property bool enabled: true
    property bool useLayoutWidth: true
    property bool isButtonUseBorder: false
    property bool showIconBackground: false
    property bool elideText: false
    property color iconColor: Colours.m3Colors.m3OnPrimary
    property color buttonColor: Colours.m3Colors.m3Primary
    property color buttonTextColor: Colours.m3Colors.m3OnBackground
    property color buttonBorderColor: Colours.m3Colors.m3Outline
    property color iconBackgroundColor: Colours.m3Colors.m3Primary
    property int textSize: Appearance.fonts.size.large
    property int iconSize: Appearance.fonts.size.medium
    property int buttonWidth: 150
    property int iconOnlyWidth: 60
    property int buttonHeight: 40
    property int iconTextSpacing: 8
    property int buttonBorderWidth: 2
    property int iconBackgroundSize: 50
    property real backgroundRounding: 0
    property real iconBackgroundRadius: Appearance.rounding.small
    property string iconButton: ""
    property string fontFamily: Appearance.fonts.family.material
    property string buttonTitle: ""
    readonly property real normalWidth: buttonTitle === "" ? iconOnlyWidth : buttonWidth
    readonly property real expandedWidth: normalWidth * 1.1
    signal clicked

    implicitWidth: useLayoutWidth ? undefined : normalWidth
    implicitHeight: buttonHeight

    Layout.preferredWidth: useLayoutWidth ? (mouseArea.pressed ? expandedWidth : normalWidth) : undefined
    Layout.preferredHeight: buttonHeight
    Layout.fillWidth: false
    Layout.alignment: Qt.AlignVCenter

    Behavior on Layout.preferredWidth {
        enabled: root.useLayoutWidth
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    ClippingRectangle {
		id: background

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: root.useLayoutWidth ? parent.width : (root.normalWidth * (mouseArea.pressed && root.enabled ? 1.1 : 1.0))
        implicitHeight: parent.height

        Behavior on implicitWidth {
            enabled: !root.useLayoutWidth
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

    RowLayout {
		id: contentRow

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.buttonTitle === "" ? undefined : parent.left
        anchors.right: root.buttonTitle === "" ? undefined : parent.right
        anchors.leftMargin: root.buttonTitle === "" ? 0 : 12
        anchors.rightMargin: root.buttonTitle === "" ? 0 : 12

        spacing: root.iconTextSpacing
        opacity: root.enabled ? 1.0 : 0.5

        Loader {
            active: root.iconButton !== ""
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: Item {
                implicitWidth: root.showIconBackground ? root.iconBackgroundSize : iconOnly.implicitWidth
                implicitHeight: root.showIconBackground ? root.iconBackgroundSize : iconOnly.implicitHeight

                Rectangle {
                    visible: root.showIconBackground
                    anchors.fill: parent
                    color: root.iconBackgroundColor
                    radius: root.iconBackgroundRadius

                    MaterialIcon {
                        anchors.centerIn: parent
                        icon: root.iconButton
                        font.family: root.fontFamily
                        font.pointSize: root.iconSize > 0 ? root.iconSize : Appearance.fonts.size.large
                        font.bold: true
                        color: root.iconColor
                    }
                }

                MaterialIcon {
					id: iconOnly

                    visible: !root.showIconBackground
                    anchors.centerIn: parent
                    icon: root.iconButton
                    font.family: root.fontFamily
                    font.pointSize: root.iconSize > 0 ? root.iconSize : Appearance.fonts.size.large
                    font.bold: true
                    color: root.iconColor
                }
            }
        }

        Loader {
            active: root.buttonTitle !== ""
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            sourceComponent: StyledText {
                text: root.buttonTitle
                font.pixelSize: root.textSize
                font.weight: Font.Medium
                color: root.buttonTextColor
                elide: Text.ElideRight
                width: Math.min(implicitWidth, contentRow.width - (root.iconButton !== "" ? (root.showIconBackground ? root.iconBackgroundSize : 24) + root.iconTextSpacing : 0))
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
