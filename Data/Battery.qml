pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
	readonly property bool charging: UPower.displayDevice.state == UPowerDeviceState.Charging
	readonly property string icon: {
		if (percentage > 0.95)
			return "battery_android_full";
		if (percentage > 0.85)
			return "battery_android_6";
		if (percentage > 0.65)
			return "battery_android_5";
		if (percentage > 0.55)
			return "battery_android_4";
		if (percentage > 0.45)
			return "battery_android_3";
		if (percentage > 0.35)
			return "battery_android_2";
		if (percentage > 0.15)
			return "battery_android_1";
		if (percentage > 0.05)
			return "battery_android_0";
		return "battery_android_0";
	}
	readonly property list<string> icons: ["battery_android_full", "battery_android_6", "battery_android_5", "battery_android_4", "battery_android_3", "battery_android_2", "battery_android_1", "battery_android_0", "battery_android_0", "battery_android_0", "battery_android_alert"]
	readonly property real percentage: UPower.displayDevice.percentage
	readonly property string chargeIcon: icons[10 - chargeIconIndex]
	property int chargeIconIndex: 0
}
