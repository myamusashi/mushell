pragma ComponentBehavior: Bound

import QtQuick

import qs.Configs
import qs.Helpers

Item {
    id: root

    property string buttonTitle
    property string iconButton: ""
	property int iconSize
    property color buttonColor: Themes.m3Colors.m3Primary
    property color buttonTextColor: Themes.m3Colors.m3OnPrimary
    property color buttonBorderColor: Themes.m3Colors.m3Outline
    property int buttonBorderWidth: 2
    property int buttonHeight: 40
    property int iconTextSpacing: 8
    property bool isButtonFullRound: true
    property bool isButtonUseBorder: false
    property real backgroundRounding: 0

    signal clicked

    implicitWidth: contentRow.implicitWidth + 32
    implicitHeight: buttonHeight

    StyledRect {
		id: background

        anchors.fill: parent
        border.color: root.isButtonUseBorder ? root.buttonBorderColor : "transparent"
        border.width: root.isButtonUseBorder ? root.buttonBorderWidth : 0
        radius: root.isButtonFullRound ? Appearance.rounding.full : root.backgroundRounding
        color: root.buttonColor
        opacity: mouseArea.pressed ? 0.8 : (mouseArea.containsMouse ? 0.9 : 1.0)
    }

    Row {
		id: contentRow

        spacing: root.iconTextSpacing
        anchors.centerIn: parent

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
                font.family: Appearance.fonts.familySans
                color: root.buttonTextColor
            }
        }
    }

    MArea {
		id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
