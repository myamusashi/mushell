pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Helpers

Button {
    id: root

    property string buttonTitle
    property string iconButton: ""
    property int iconSize
    property color buttonColor: Themes.m3Colors.primary
    property color buttonTextColor: Themes.m3Colors.onPrimary
    property color buttonBorderColor: Themes.m3Colors.outline
    property int buttonBorderWidth: 2
    property int buttonHeight: 40
    property int iconTextSpacing: 8
    property bool isButtonFullRound: true
    property bool isButtonUseBorder: false
    property real backgroundRounding: 0

    readonly property real contentOpacity: pressed ? 0.12 : hovered ? 0.08 : 1.0

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: buttonHeight
    hoverEnabled: true

    contentItem: RowLayout {
        spacing: root.iconTextSpacing
        opacity: root.contentOpacity
        anchors.centerIn: parent

        Loader {
            active: root.iconButton !== ""
            Layout.alignment: Qt.AlignCenter
            sourceComponent: MaterialIcon {
                icon: root.iconButton
                font.pointSize: Appearance.fonts.large
                font.bold: true
                color: root.buttonTextColor
            }
        }

        Loader {
            active: root.buttonTitle !== ""
            Layout.alignment: Qt.AlignCenter
            sourceComponent: Text {
                text: root.buttonTitle
                font.pixelSize: Appearance.fonts.large
                font.weight: Font.Medium
                font.family: Appearance.fonts.familySans
                color: root.buttonTextColor
                renderType: Text.NativeRendering
            }
        }
    }

    background: Rectangle {
        border.color: root.isButtonUseBorder ? root.buttonBorderColor : "transparent"
        border.width: root.isButtonUseBorder ? root.buttonBorderWidth : 0
        radius: Appearance.rounding.full
        color: root.buttonColor
        opacity: root.contentOpacity

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }
}
