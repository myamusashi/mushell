import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data

Slider {
	id: root

	hoverEnabled: true
	property int handleHeight: 15
	property int handleWidth: 15
	required property int valueWidth
	required property int valueHeight
	property int sliderOrientation: Qt.Horizontal // Ganti nama property
	Layout.alignment: Qt.AlignHCenter

	// Set orientation bawaan QML Slider
	orientation: sliderOrientation

	background: Item {
		implicitWidth: root.valueWidth
		implicitHeight: root.valueHeight
		width: root.availableWidth
		height: root.availableHeight
		x: root.leftPadding
		y: root.topPadding

		Rectangle {
			id: unprogressBackground

			width: root.sliderOrientation === Qt.Horizontal ? parent.width : parent.height
			height: root.sliderOrientation === Qt.Horizontal ? parent.height : parent.width
			x: root.sliderOrientation === Qt.Horizontal ? 0 : (parent.width - width) / 2
			y: root.sliderOrientation === Qt.Horizontal ? (parent.height - height) / 2 : 0
			color: Appearance.colors.withAlpha(Appearance.colors.primary, 0.1)
			radius: Appearance.rounding.small
		}

		Rectangle {
			id: progressBackground

			width: root.sliderOrientation === Qt.Horizontal ? parent.width * root.visualPosition : unprogressBackground.width
			height: root.sliderOrientation === Qt.Horizontal ? unprogressBackground.height : parent.height * root.visualPosition
			x: root.sliderOrientation === Qt.Horizontal ? 0 : (parent.width - width) / 2
			y: root.sliderOrientation === Qt.Horizontal ? (parent.height - height) / 2 : parent.height - height
			color: Appearance.colors.withAlpha(Appearance.colors.primary, 0.8)
			radius: Appearance.rounding.small
		}
	}

	handle: Rectangle {
		id: sliderHandle

		x: root.sliderOrientation === Qt.Horizontal ? root.leftPadding + root.visualPosition * (root.availableWidth - width) : root.leftPadding + root.availableWidth / 2 - width / 2
		y: root.sliderOrientation === Qt.Horizontal ? root.topPadding + root.availableHeight / 2 - height / 2 : root.topPadding + (1 - root.visualPosition) * (root.availableHeight - height)
		implicitWidth: root.handleWidth
		implicitHeight: root.handleHeight
		radius: width / 2
		color: root.pressed ? Appearance.colors.primary : Appearance.colors.on_surface

		Rectangle {
			anchors.centerIn: parent
			width: root.pressed ? 28 : (root.hovered ? 24 : 0)
			height: width
			radius: width / 2
			color: Appearance.colors.withAlpha(Appearance.colors.primary, 0.12)
			visible: root.pressed || root.hovered

			Behavior on width {
				NumbAnim {}
			}
		}
	}
}
