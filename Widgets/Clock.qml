import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components
import qs.Modules.Calendar

StyledRect {
	Layout.fillHeight: true
	color: "transparent"
	// color: Themes.colors.withAlpha(Themes.colors.background, 0.79)
	implicitWidth: timeContainer.width + 15
	radius: Appearance.rounding.small

	Dots {
		id: timeContainer

		MatIcon {
			id: icon

			color: Themes.colors.on_background
			font.bold: true
			font.pixelSize: Appearance.fonts.large * 1.2
			icon: "schedule"
		}

		StyledText {
			id: text

			color: Themes.colors.on_background
			font.bold: true
			font.pixelSize: Appearance.fonts.medium
			text: Qt.formatDateTime(Time?.date, "h:mm AP")
		}
	}
	MArea {
		id: mArea

		anchors.fill: timeContainer
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: cal.isCalendarShow = !cal.isCalendarShow
	}

	Calendar {
		id: cal
	}
}
