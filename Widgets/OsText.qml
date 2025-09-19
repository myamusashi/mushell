import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers

Rectangle {
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
		}
	}
}
