import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	active: root.isBarOpen
	asynchronous: true

	height: parent.height / 1 - 5
	width: parent.width + 10

	sourceComponent: Rectangle {
		Layout.fillHeight: true
		color: "transparent"
		// color: Appearance.colors.withAlpha(Appearance.colors.background, 0.79)
		implicitWidth: container.width
		radius: 5

		Dots {
			id: container

			MatIcon {
				Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
				color: Appearance.colors.tertiary
				font.family: Appearance.fonts.family_Mono
				font.pixelSize: Appearance.fonts.large * 1.7
				icon: "󱄅"

				MouseArea {
					id: mArea

					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: menu.isMenuOpen = !menu.isMenuOpen
				}
			}
		}
		Menu {
			id: menu
		}
	}
}
