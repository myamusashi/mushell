import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data

Slider {
	id: root

	hoverEnabled: true
	Layout.alignment: Qt.AlignHCenter

	background: Item {
		implicitWidth: 300
		implicitHeight: 10
		width: root.availableWidth
		x: root.leftPadding
		y: root.topPadding + root.availableHeight / 2 - height / 2

		Rectangle {
			id: unprogressBackground

			anchors.fill: parent
			color: Appearance.colors.withAlpha(Appearance.colors.primary, 0.1)
			radius: Appearance.rounding.small
		}

		Rectangle {
			id: progressBackground

			width: parent.width * root.visualPosition
			height: parent.height
			color: Appearance.colors.withAlpha(Appearance.colors.primary, 0.8)
			radius: Appearance.rounding.small
		}
	}

	handle: Rectangle {
		id: sliderHandle

		x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
		y: root.topPadding + root.availableHeight / 2 - height / 2
		implicitWidth: 15
		implicitHeight: 15
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
