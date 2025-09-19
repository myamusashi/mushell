import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Components
import qs.Helpers

Rectangle {
	Layout.fillHeight: true
	color: "transparent"
	// color: Appearance.colors.withAlpha(Appearance.colors.background, 0.79)
	implicitWidth: timeContainer.width + 15
	radius: Appearance.rounding.small

	Dots {
		id: timeContainer

		MatIcon {
			id: icon

			color: Appearance.colors.on_background
			font.bold: true
			font.pixelSize: Appearance.fonts.large * 1.2
			icon: "schedule"
		}

		StyledText {
			id: text

			color: Appearance.colors.on_background
			font.bold: true
			font.pixelSize: Appearance.fonts.medium
			text: Qt.formatDateTime(Time?.date, "h:mm AP")
		}
	}
}
