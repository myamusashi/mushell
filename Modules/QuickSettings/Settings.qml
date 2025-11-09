import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

ColumnLayout {
	anchors.fill: parent
	spacing: 15

	RowLayout {
		Layout.fillWidth: true
		Layout.fillHeight: true

		ColumnLayout {
			Layout.fillHeight: true
			Layout.fillWidth: true
			Layout.margins: 15
			Layout.alignment: Qt.AlignLeft | Qt.AlignTop

			StyledRect {
				Layout.fillWidth: true
				Layout.preferredHeight: 140
				color: Colors.colors.surface_container_low
				radius: Appearance.rounding.normal

				ColumnLayout {
					anchors.fill: parent
					anchors.rightMargin: 10
					anchors.leftMargin: 10
					anchors.bottomMargin: 25
					spacing: Appearance.spacing.small

					Item {
						Layout.fillWidth: true
						Layout.preferredHeight: 60

						MatIcon {
							id: batteryIcon
							anchors.centerIn: parent
							icon: Battery.charging ? Battery.chargeIcon : Battery.icon
							color: Battery.charging ? Colors.colors.on_primary : Colors.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.extraLarge * 3
						}

						RowLayout {
							anchors.centerIn: parent
							spacing: 4

							MatIcon {
								icon: "bolt"
								color: Colors.colors.primary
								visible: Battery.charging
								font.pixelSize: Appearance.fonts.medium
							}

							StyledText {
								text: (UPower.displayDevice.percentage * 100).toFixed(0)
								color: Colors.colors.surface
								font.pixelSize: Appearance.fonts.large
								font.bold: true
							}
						}
					}

					ColumnLayout {
						Layout.fillWidth: true
						spacing: Appearance.spacing.small

						RowLayout {
							Layout.fillWidth: true
							spacing: Appearance.spacing.small

							StyledText {
								text: "Current capacity:"
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.small
							}

							Item {
								Layout.fillWidth: true
							}

							StyledText {
								text: UPower.displayDevice.energy.toFixed(2) + " Wh"
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.small
								font.bold: true
							}
						}

						RowLayout {
							Layout.fillWidth: true
							spacing: Appearance.spacing.small

							StyledText {
								text: "Full capacity:"
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.small
							}

							Item {
								Layout.fillWidth: true
							}

							StyledText {
								text: UPower.displayDevice.energyCapacity.toFixed(2) + " Wh"
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.small
								font.bold: true
							}
						}

						RowLayout {
							Layout.fillWidth: true
							spacing: Appearance.spacing.small

							StyledText {
								text: "Battery Health:"
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.small
							}

							Item {
								Layout.fillWidth: true
							}

							StyledText {
								text: ((UPower.displayDevice.energy / UPower.displayDevice.energyCapacity) * 100).toFixed(1) + "%"
								color: {
									var health = (UPower.displayDevice.energy / UPower.displayDevice.energyCapacity) * 100;
									return health > 80 ? Colors.colors.primary : health > 50 ? Colors.colors.secondary : Colors.colors.error;
								}
								font.pixelSize: Appearance.fonts.small
								font.bold: true
							}
						}
					}
				}

				Timer {
					interval: 600
					repeat: true
					running: Battery.charging
					triggeredOnStart: true
					onTriggered: {
						Battery.chargeIconIndex = (Battery.chargeIconIndex % 10) + 1;
					}
				}
			}
		}

		ColumnLayout {
			Layout.fillHeight: true
			Layout.fillWidth: true
			Layout.margins: 15
			Layout.alignment: Qt.AlignLeft | Qt.AlignTop
			spacing: Appearance.spacing.normal

			StyledRect {
				Layout.fillWidth: true
				Layout.preferredHeight: 65
				color: Colors.colors.surface_container
				radius: Appearance.rounding.normal

				RowLayout {
					anchors.fill: parent
					anchors.margins: Appearance.margin.normal
					spacing: Appearance.spacing.normal

					Rectangle {
						Layout.preferredWidth: 50
						Layout.fillHeight: true
						color: Colors.colors.primary_container
						radius: Appearance.rounding.small

						MatIcon {
							anchors.centerIn: parent
							icon: "settings_ethernet"
							color: Colors.colors.on_primary
							font.pixelSize: Appearance.fonts.extraLarge
						}
					}

					Column {
						Layout.fillWidth: true
						spacing: 2

						StyledText {
							text: "Ethernet"
							font.pixelSize: Appearance.fonts.normal
							font.weight: Font.Medium
							color: Colors.colors.on_surface
						}

						StyledText {
							text: "Not Connected"
							font.pixelSize: Appearance.fonts.small
							color: Colors.colors.on_surface_variant
						}
					}
				}
			}

			StyledRect {
				id: wifi

				Layout.fillWidth: true
				Layout.preferredHeight: 65
				color: Colors.colors.surface_container
				radius: Appearance.rounding.normal

				property var activeNetwork: {
					for (let i = 0; i < NetworkManager.networks.length; i++)
						if (NetworkManager.networks[i].active)
							return NetworkManager.networks[i];
					return null;
				}

				RowLayout {
					anchors.fill: parent
					anchors.margins: Appearance.margin.normal
					spacing: Appearance.spacing.normal

					Rectangle {
						Layout.preferredWidth: 50
						Layout.fillHeight: true
						color: wifi.activeNetwork ? Colors.colors.primary : Colors.withAlpha(Colors.colors.on_surface, 0.1)
						radius: Appearance.rounding.small

						MatIcon {
							anchors.centerIn: parent
							icon: {
								if (wifi.activeNetwork) {
									var strength = wifi.activeNetwork.strength;
									if (strength >= 80)
										return "network_wifi_4_bar";
									else if (strength >= 50)
										return "network_wifi_3_bar";
									else if (strength >= 30)
										return "network_wifi_2_bar";
									else if (strength >= 15)
										return "network_wifi_1_bar";
									else
										return "signal_wifi_0_bar";
								} else {
									return "wifi_off";
								}
							}
							color: wifi.activeNetwork ? Colors.colors.on_primary : Colors.withAlpha(Colors.colors.on_surface, 0.38)
							font.pixelSize: Appearance.fonts.extraLarge
						}
					}

					Column {
						Layout.fillWidth: true
						spacing: 2

						StyledText {
							text: "Internet"
							font.pixelSize: Appearance.fonts.small
							color: Colors.colors.on_surface_variant
						}

						StyledText {
							text: wifi.activeNetwork ? wifi.activeNetwork.ssid : "WiFi Disconnected"
							font.pixelSize: Appearance.fonts.normal
							font.weight: Font.Medium
							color: Colors.colors.on_surface
						}
					}
				}
			}
		}
	}

	RowLayout {
		Layout.fillWidth: true
		Layout.columnSpan: 2
		spacing: Appearance.spacing.normal
		Layout.rightMargin: 15
		Layout.leftMargin: 15

		Repeater {
			model: [
				{
					icon: "energy_savings_leaf",
					name: "Power save",
					profile: PowerProfile.PowerSaver
				},
				{
					icon: "balance",
					name: "Balanced",
					profile: PowerProfile.Balanced
				},
				{
					icon: "rocket_launch",
					name: "Performance",
					profile: PowerProfile.Performance
				},
			]

			delegate: StyledButton {
				required property var modelData

				iconButton: modelData.icon
				buttonTitle: modelData.name
				buttonColor: modelData.profile === PowerProfiles.profile ? Colors.colors.primary : Colors.withAlpha(Colors.colors.on_surface, 0.1)
				buttonTextColor: modelData.profile === PowerProfiles.profile ? Colors.colors.on_primary : Colors.withAlpha(Colors.colors.on_surface, 0.38)
				onClicked: PowerProfiles.profile = modelData.profile
			}
		}
	}

	RowLayout {
		Layout.fillWidth: true
		spacing: Appearance.spacing.normal
		Layout.rightMargin: 15
		Layout.leftMargin: 15

		StyledSlide {
			id: brightnessSlider

			Layout.alignment: Qt.AlignLeft
			Layout.fillWidth: true
			Layout.preferredHeight: 48

			icon: "brightness_5"
			iconSize: Appearance.fonts.large * 1.5

			from: 0
			to: Brightness.maxValue || 1
			value: Brightness.value
			progressBackgroundHeight: 44

			onMoved: debounceTimer.restart()

			Timer {
				id: debounceTimer
				interval: 150
				repeat: false
				onTriggered: Brightness.setBrightness(brightnessSlider.value)
			}
		}

		StyledButton {
			iconButton: "bedtime"
			buttonTitle: "Night mode"
			buttonTextColor: {
				if (Hyprsunset.isNightModeOn)
					return Colors.colors.on_primary;
				else
					return Colors.withAlpha(Colors.colors.on_surface, 0.38);
			}
			buttonColor: {
				if (Hyprsunset.isNightModeOn)
					return Colors.colors.primary;
				else
					return Colors.withAlpha(Colors.colors.on_surface, 0.1);
			}
			onClicked: Hyprsunset.isNightModeOn ? Hyprsunset.down() : Hyprsunset.up()
		}
	}

	RowLayout {
		Layout.fillWidth: true
		spacing: Appearance.spacing.normal
		Layout.rightMargin: 15
		Layout.leftMargin: 15

		StyledButton {
			iconButton: "screenshot_frame"
			buttonTitle: "Screenshot"
			onClicked: () => {
				Quickshell.execDetached({
					command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-selection"]
				});
			}
		}

		StyledButton {
			iconButton: "screen_record"
			buttonTitle: "Screen record"
			onClicked: () => {
				Quickshell.execDetached({
					command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-selection"]
				});
			}
		}

		StyledButton {
			iconButton: "content_paste"
			buttonTitle: "Clipboard"
			onClicked: () => {
				Quickshell.execDetached({
					command: ["sh", "-c", Quickshell.shellDir + "kitty --class clipse -e clipse"]
				});
			}
		}
	}

	Item {
		Layout.fillHeight: true
	}
}
