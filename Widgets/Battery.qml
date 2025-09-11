import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Data
import qs.Helpers

Rectangle {
	id: root

	readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
	readonly property string batIcon: {
		(batPercentage > 0.98) ? batIcons[0] : (batPercentage > 0.90) ? batIcons[1] : (batPercentage > 0.80) ? batIcons[2] : (batPercentage > 0.70) ? batIcons[3] : (batPercentage > 0.60) ? batIcons[4] : (batPercentage > 0.50) ? batIcons[5] : (batPercentage > 0.40) ? batIcons[6] : (batPercentage > 0.30) ? batIcons[7] : (batPercentage > 0.20) ? batIcons[8] : (batPercentage > 0.10) ? batIcons[9] : batIcons[10];
	}
	readonly property list<string> batIcons: ["󰁹", "󰂂", "󰂁", "󰂀", "󰁿", "󰁾", "󰁽", "󰁼", "󰁻", "󰁺", "󰂃"]
	readonly property real batPercentage: UPower.displayDevice.percentage
	readonly property string chargeIcon: batIcons[10 - chargeIconIndex]
	property int chargeIconIndex: 0
	property int padding: 16

	Layout.fillHeight: true
	// color: Appearance.colors.withAlpha(Appearance.colors.background, 0.79)
	color: "transparent"
	implicitWidth: container.width + padding
	radius: 5

	Dots {
		id: container

		spacing: Appearance.spacing.small

		icon {
			color: Appearance.colors.tertiary
			font.family: Appearance.fonts.family_Mono
			font.pixelSize: Appearance.fonts.medium * 1.4
			text: (root.batCharging) ? root.chargeIcon : root.batIcon
		}

		text {
			color: Appearance.colors.tertiary
			font.pixelSize: Appearance.fonts.medium
			text: (UPower.displayDevice.percentage * 100).toFixed(0) + "%"
		}
	}

	Timer {
		interval: 600
		repeat: true
		running: root.batCharging
		triggeredOnStart: true

		onTriggered: () => {
			root.chargeIconIndex = root.chargeIconIndex % 10;
			root.chargeIconIndex += 1;
		}
	}
}
