pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	active: dashboardLoader.activeAsync
	asynchronous: true

	anchors.fill: parent

	sourceComponent: Rectangle {
	anchors.fill: parent
	color: Appearance.colors.background
	radius: Appearance.rounding.normal
	border.color: Appearance.colors.outline
	border.width: 2

	ColumnLayout {
		id: root

		anchors.fill: parent
		anchors.margins: Appearance.margin.normal
		spacing: Appearance.spacing.normal

		property date currentDate: new Date()
		property int currentYear: currentDate.getFullYear()
		property int currentMonth: currentDate.getMonth()
		property int cellWidth: Math.floor((width - anchors.margins * 2) / 7.2)

		RowLayout {
			Layout.fillWidth: true
			Layout.preferredHeight: 48
			spacing: Appearance.spacing.normal

			Rectangle {
				Layout.preferredWidth: 40
				Layout.preferredHeight: 40
				radius: Appearance.rounding.full
				color: {
					if (prevMouseArea.containsMouse && prevMouseArea.containsPress)
						return Appearance.colors.withAlpha(Appearance.colors.primary, 0.12);
					else if (prevMouseArea.containsMouse)
						return Appearance.colors.withAlpha(Appearance.colors.primary, 0.08);
					else
						return "transparent";
				}

				MatIcon {
					id: prevIcon

					anchors.centerIn: parent
					icon: "chevron_left"
					font.pixelSize: Appearance.fonts.large * 2
					color: Appearance.colors.on_primary_container
				}

				MouseArea {
					id: prevMouseArea

					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					hoverEnabled: true
					onClicked: {
						root.currentMonth = root.currentMonth - 1;
						if (root.currentMonth < 0) {
							root.currentMonth = 11;
							root.currentYear = root.currentYear - 1;
						}
					}
				}
			}

			StyledText {
				Layout.fillWidth: true
				text: {
					const monthNames = Array.from({
						length: 12
					}, (_, i) => Qt.locale().monthName(i, Qt.locale().LongFormat));
					return monthNames[root.currentMonth] + " " + root.currentYear;
				}
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				font.weight: 600
				color: Appearance.colors.on_background
				font.pixelSize: Appearance.fonts.large
			}

			Rectangle {
				Layout.preferredWidth: 40
				Layout.preferredHeight: 40
				radius: Appearance.rounding.full
				color: {
					if (nextMouseArea.containsMouse && nextMouseArea.containsPress)
						return Appearance.colors.withAlpha(Appearance.colors.primary, 0.12);
					else if (nextMouseArea.containsMouse)
						return Appearance.colors.withAlpha(Appearance.colors.primary, 0.08);
					else
						return "transparent";
				}

				MatIcon {
					id: nextIcon
					anchors.centerIn: parent
					icon: "chevron_right"
					font.pixelSize: Appearance.fonts.large * 2
					color: Appearance.colors.primary
				}

				MouseArea {
					id: nextMouseArea

					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					hoverEnabled: true
					onClicked: {
						root.currentMonth = root.currentMonth + 1;
						if (root.currentMonth > 11) {
							root.currentMonth = 0;
							root.currentYear = root.currentYear + 1;
						}
					}
				}
			}
		}

		DayOfWeekRow {
			Layout.fillWidth: true
			Layout.topMargin: Appearance.spacing.small
			Layout.preferredHeight: 32

			delegate: Rectangle {
				id: daysOfWeekDelegate

				required property var model

				implicitWidth: root.cellWidth
				implicitHeight: 32
				color: "transparent"

				StyledText {
					anchors.centerIn: parent
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					text: daysOfWeekDelegate.model.shortName
					color: Appearance.colors.on_surface_variant
					font.pixelSize: Appearance.fonts.small * 1.2
					font.weight: 600
				}
			}
		}

		MonthGrid {
			id: monthGrid

			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.topMargin: Appearance.spacing.small

			property int cellWidth: root.cellWidth
			property int cellHeight: Math.floor(height / 7)

			month: root.currentMonth
			year: root.currentYear

			delegate: Rectangle {
				id: dayItem

				required property var model

				width: monthGrid.cellWidth
				height: monthGrid.cellHeight

				color: {
					if (dayItem.model.today)
						return Appearance.colors.primary;
					else if (mouseArea.containsMouse && dayItem.model.month === root.currentMonth)
						return Appearance.colors.surface_variant;

					return "transparent";
				}

				radius: Appearance.rounding.small

				implicitWidth: 40
				implicitHeight: 40

				MouseArea {
					id: mouseArea

					anchors.fill: parent
					hoverEnabled: true
					visible: dayItem.model.month === root.currentMonth
					cursorShape: Qt.PointingHandCursor
					onClicked: {}
				}

				StyledText {
					anchors.centerIn: parent
					text: Qt.formatDate(dayItem.model.date, "d")
					color: {
						if (dayItem.model.today)
							return Appearance.colors.on_primary;
						else if (dayItem.model.month === root.currentMonth)
							return Appearance.colors.on_surface;
						else
							return Appearance.colors.outline;
					}
					font.pixelSize: Appearance.fonts.small * 1.3
					font.weight: {
						if (dayItem.model.today)
							return 1000;
						else if (dayItem.model.month === root.currentMonth)
							return 600;
						else
							return 100;
					}
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
				}
			}
		}
	}
}
}
