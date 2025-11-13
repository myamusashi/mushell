import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	Variants {
		model: Quickshell.screens

		delegate: WlrLayershell {
			id: root

			required property ShellScreen modelData

			anchors {
				top: true
				right: true
				left: true
				bottom: true
			}

			namespace: "shell:bigclock"
			layer: WlrLayer.Background
			screen: modelData
			color: "transparent"

			exclusiveZone: 0

			StyledRect {
				anchors.centerIn: parent

				color: "transparent"

				ColumnLayout {
					id: clock

					anchors.centerIn: parent
					spacing: Appearance.spacing.normal

					StyledText {
						id: hours

						Layout.alignment: Qt.AlignCenter
						text: Qt.formatDateTime(Time?.date, "h:mm AP")
						font.pixelSize: Appearance.fonts.extraLarge * 2.5
						font.bold: true
						antialiasing: true
						color: Themes.colors.secondary
					}

					RowLayout {
						Layout.alignment: Qt.AlignCenter

						StyledText {
							id: day

							text: Qt.formatDateTime(Time?.date, "dddd")
							font.pixelSize: Appearance.fonts.large
							color: Themes.withAlpha(Themes.colors.secondary, 1)
							antialiasing: true
						}

						StyledText {
							id: month

							text: Qt.formatDateTime(Time?.date, "MMMM")
							font.pixelSize: Appearance.fonts.large
							color: Themes.withAlpha(Themes.colors.secondary, 1)
							antialiasing: true
						}

						StyledText {
							id: year

							text: Qt.formatDateTime(Time?.date, "yyyy")
							font.pixelSize: Appearance.fonts.large
							color: Themes.withAlpha(Themes.colors.secondary, 1)
							antialiasing: true
						}

						IconImage {
							id: weatherIcon

							Layout.alignment: Qt.AlignHCenter
							implicitSize: 37
							source: Qt.resolvedUrl("https://openweathermap.org/img/wn/" + Weather.weatherIconData
												   + "@4x.png") || Quickshell.iconPath("stock_weather-cloudy")
							asynchronous: true
							smooth: true
						}

						StyledText {
							id: temp

							text: Weather.tempData + "°"
							font.pixelSize: Appearance.fonts.large
							color: Themes.withAlpha(Themes.colors.secondary, 1)
							antialiasing: true
						}

						MatIcon {
							id: huy
							icon: "humidity_low"
							font.pixelSize: Appearance.fonts.large
							color: Themes.withAlpha(Themes.colors.secondary, 1)
							antialiasing: true
						}

						StyledText {
							id: humidity

							text: Weather.humidityData + "%"
							font.pixelSize: Appearance.fonts.large
							color: Themes.withAlpha(Themes.colors.secondary, 1)
							antialiasing: true
						}
					}
				}
			}
		}
	}
}
