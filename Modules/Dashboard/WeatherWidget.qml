import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

StyledRect {
	id: root

	implicitWidth: 400
	implicitHeight: 420

	radius: Appearance.rounding.normal
	color: Colors.colors.background
	border.color: Colors.colors.outline
	border.width: 2

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: Appearance.margin.normal
		spacing: Appearance.spacing.normal

		StyledText {
			Layout.alignment: Qt.AlignHCenter
			text: Weather.cityData

			color: Colors.colors.on_surface
			font.pixelSize: Appearance.fonts.large * 1.2
			font.weight: Font.Bold
		}

		RowLayout {
			Layout.fillWidth: false
			Layout.alignment: Qt.AlignHCenter
			Layout.topMargin: 10
			Layout.bottomMargin: 10
			spacing: Appearance.spacing.normal

			MatIcon {
				id: weatherIcon

				Layout.alignment: Qt.AlignHCenter
				font.pixelSize: Appearance.fonts.extraLarge * 4
				color: Colors.colors.primary
				icon: "air"
			}

			StyledText {
				Layout.alignment: Qt.AlignVCenter
				text: Weather.tempData + "°C"
				color: Colors.colors.primary
				font.pixelSize: Appearance.fonts.extraLarge * 2.5
				font.weight: Font.Light
			}
		}

		StyledText {
			Layout.alignment: Qt.AlignHCenter
			text: Weather.weatherDescriptionData.charAt(0).toUpperCase() + Weather.weatherDescriptionData.slice(1)
			color: Colors.colors.on_surface_variant
			font.pixelSize: Appearance.fonts.normal * 1.5
			wrapMode: Text.WordWrap
			horizontalAlignment: Text.AlignHCenter
		}

		Item {
			Layout.fillWidth: true
		}

		StyledRect {
			Layout.fillWidth: true
			Layout.preferredHeight: 80
			color: "transparent"

			RowLayout {
				anchors.centerIn: parent
				spacing: Appearance.spacing.large * 5

				ColumnLayout {
					Layout.fillWidth: true
					spacing: Appearance.spacing.small

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						text: Weather.tempMinData + "° / " + Weather.tempMaxData + "°"
						color: Colors.colors.on_surface
						font.weight: Font.Bold
						font.pixelSize: Appearance.fonts.small * 1.5
					}
					StyledText {
						Layout.alignment: Qt.AlignHCenter
						text: "Min / Max"
						color: Colors.colors.on_surface_variant
						font.pixelSize: Appearance.fonts.small * 1.2
					}
				}

				ColumnLayout {
					Layout.fillWidth: true
					spacing: 5

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						text: Weather.humidityData + "%"
						color: Colors.colors.on_surface
						font.weight: Font.Bold
						font.pixelSize: Appearance.fonts.small * 1.5
					}
					StyledText {
						Layout.alignment: Qt.AlignHCenter
						text: "Kelembapan"
						color: Colors.colors.on_surface_variant
						font.pixelSize: Appearance.fonts.small * 1.2
					}
				}

				ColumnLayout {
					Layout.fillWidth: true
					spacing: 5

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						text: Weather.windSpeedData + " m/s"
						color: Colors.colors.on_surface
						font.weight: Font.Bold
						font.pixelSize: Appearance.fonts.small * 1.5
					}
					StyledText {
						Layout.alignment: Qt.AlignHCenter
						text: "Angin"
						color: Colors.colors.on_surface_variant
						font.pixelSize: Appearance.fonts.small * 1.2
					}
				}
			}
		}
	}
}
