import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Helpers

Button {
	id: root

	property string buttonTitle
	property string iconButton: ""
	property int iconSize
	property color buttonColor: Themes.colors.primary
	property color buttonTextColor: Themes.colors.on_primary
	property color buttonBorderColor: Themes.colors.outline
	property int buttonBorderWidth: 2
	property int buttonHeight: 40
	property int iconTextSpacing: 8
	property bool isButtonFullRound: true
	property bool isButtonUseBorder: false
	property real backgroundRounding: 0

	implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
	implicitHeight: buttonHeight
	hoverEnabled: true

	contentItem: RowLayout {
		spacing: root.iconTextSpacing

		MatIcon {
			icon: root.iconButton
			font.pixelSize: Appearance.fonts.large * 1.2 + root.iconSize
			font.bold: true
			visible: root.iconButton !== ""
			color: root.buttonTextColor
			opacity: root.pressed ? 0.12 : root.hovered ? 0.08 : 1.0
		}

		StyledText {
			text: root.buttonTitle
			font.pixelSize: Appearance.fonts.large
			font.weight: Font.Medium
			color: root.buttonTextColor
			opacity: root.pressed ? 0.12 : root.hovered ? 0.08 : 1.0
			visible: text !== ""
		}
	}

	background: StyledRect {
		border.color: root.isButtonUseBorder ? root.buttonBorderColor : "transparent"
		border.width: root.isButtonUseBorder ? root.buttonBorderWidth : 0
		radius: Appearance.rounding.full
		color: root.buttonColor
		opacity: root.pressed ? 0.12 : root.hovered ? 0.08 : 1.0

		Behavior on opacity {
			NumberAnimation {
				duration: Appearance.animations.durations.small
				easing.type: Easing.OutCubic
			}
		}
	}
}
