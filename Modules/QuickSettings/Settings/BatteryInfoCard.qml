import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Data
import qs.Helpers
import qs.Components

ColumnLayout {
	Layout.alignment: Qt.AlignLeft | Qt.AlignTop

	StyledRect {
		Layout.fillWidth: true
		Layout.preferredHeight: 140
		color: Colors.colors.surface_container_low
		radius: Appearance.rounding.normal

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 10
			anchors.bottomMargin: 25
			spacing: Appearance.spacing.small

			Item {
				Layout.fillWidth: true
				Layout.preferredHeight: 60

				MatIcon {
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
						color: Battery.charging ? Colors.colors.primary : Colors.colors.surface
						visible: Battery.charging
						font.pixelSize: Appearance.fonts.large
					}

					StyledText {
						text: (UPower.displayDevice.percentage * 100).toFixed(0)
						color: Battery.charging ? Colors.colors.primary : Colors.colors.surface
						font.pixelSize: Appearance.fonts.large
						font.bold: true
					}
				}
			}

			BatteryDetailsList {
				Layout.fillWidth: true
				Layout.fillHeight: true
			}
		}

		Timer {
			interval: 600
			repeat: true
			running: Battery.charging
			triggeredOnStart: true
			onTriggered: Battery.chargeIconIndex = (Battery.chargeIconIndex % 10) + 1
		}
	}

	component BatteryDetailsList: ColumnLayout {
		spacing: Appearance.spacing.small

		readonly property var details: [
			{
				label: "Battery found:",
				value: Battery.foundBattery,
				color: Colors.colors.on_background
			},
			{
				label: "Current capacity:",
				value: UPower.displayDevice.energy.toFixed(2) + " Wh",
				color: Colors.colors.on_background
			},
			{
				label: "Full capacity:",
				value: UPower.displayDevice.energyCapacity.toFixed(2) + " Wh",
				color: Colors.colors.on_background
			},
			{
				label: "Battery Health:",
				value: Battery.overallBatteryHealth,
				color: getHealthColor(Battery.overallBatteryHealth)
			}
		]

		function getHealthColor(health) {
			if (health > 80)
				return Colors.colors.primary;
			if (health > 50)
				return Colors.colors.secondary;
			return Colors.colors.error;
		}

		Repeater {
			model: parent.details

			delegate: RowLayout {
				required property var modelData

				Layout.fillWidth: true
				spacing: Appearance.spacing.small

				StyledText {
					text: parent.modelData.label
					color: Colors.colors.on_background
					font.pixelSize: Appearance.fonts.small
				}

				Item {
					Layout.fillWidth: true
				}

				StyledText {
					text: parent.modelData.value
					color: parent.modelData.color
					font.pixelSize: Appearance.fonts.small
					font.bold: true
				}
			}
		}
	}
}
