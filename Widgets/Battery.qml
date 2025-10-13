import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Data
import qs.Components
import qs.Helpers

StyledRect {
	id: root

	readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
	readonly property string batIcon: {
		if (batPercentage > 0.95)
			return "battery_android_full";
		if (batPercentage > 0.85)
			return "battery_android_6";
		if (batPercentage > 0.65)
			return "battery_android_5";
		if (batPercentage > 0.55)
			return "battery_android_4";
		if (batPercentage > 0.45)
			return "battery_android_3";
		if (batPercentage > 0.35)
			return "battery_android_2";
		if (batPercentage > 0.15)
			return "battery_android_1";
		if (batPercentage > 0.05)
			return "battery_android_0";
		return "battery_android_0";
	}
	readonly property list<string> batIcons: ["battery_android_full"    // 96-100%
		, "battery_android_6"       // 86-95%
		, "battery_android_5"       // 66-85%
		, "battery_android_4"       // 56-65%
		, "battery_android_3"       // 46-55%
		, "battery_android_2"       // 36-45%
		, "battery_android_1"       // 16-35%
		, "battery_android_0"       // 6-15%
		, "battery_android_0"       // 6-15%
		, "battery_android_0"       // 6-15%
		, "battery_android_alert"    // 0-5% (only when not charging)
	]
	readonly property real batPercentage: UPower.displayDevice.percentage
	readonly property string chargeIcon: batIcons[10 - chargeIconIndex]
	property int chargeIconIndex: 0

	Layout.fillHeight: true
	// color: Colors.colors.withAlpha(Colors.colors.background, 0.79)
	color: "transparent"
	implicitWidth: container.width
	radius: Appearance.rounding.small

	Dots {
		id: container

		spacing: Appearance.spacing.small

		MatIcon {
			color: Colors.colors.on_background
			font.pixelSize: Appearance.fonts.large * 1.2
			Layout.alignment: Qt.AlignVCenter
			icon: (root.batCharging) ? root.chargeIcon : root.batIcon
		}

		StyledText {
			color: Colors.colors.on_background
			font.pixelSize: Appearance.fonts.medium
			Layout.alignment: Qt.AlignVCenter
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
