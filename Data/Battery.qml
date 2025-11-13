pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
	id: root

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
	readonly property list<string> icons: ["battery_android_full", "battery_android_6",
		"battery_android_5", "battery_android_4", "battery_android_3", "battery_android_2",
		"battery_android_1", "battery_android_0", "battery_android_0", "battery_android_0",
		"battery_android_alert"]
	readonly property real percentage: UPower.displayDevice.percentage
	readonly property string chargeIcon: icons[10 - chargeIconIndex]
	property int chargeIconIndex: 0
	property int foundBattery
	property real fullDesignCapacity
	property real currentDesignCapacity
	property real overallBatteryHealth

	Process {
		command: ["sh", "-c", "ls -d /sys/class/power_supply/BAT* | wc -l"]
		running: true
		stdout: StdioCollector {
			onStreamFinished: {
				root.foundBattery = parseInt(text.trim());
			}
		}
	}

	Process {
		id: batteryHealthProc

		command: ["sh", "-c",
			"cat /sys/class/power_supply/BAT*/energy_full_design && cat /sys/class/power_supply/BAT*/energy_full"]
		running: true
		stdout: StdioCollector {
			onStreamFinished: {
				const lines = text.trim().split('\n');
				const values = lines.map(line => parseInt(line));

				const designCapacities = [];
				const currentCapacities = [];

				for (let i = 0; i < values.length; i++) {
					if (i % 2 === 0)
					designCapacities.push(values[i]);
					else
					currentCapacities.push(values[i]);
				}

				const totalDesign = designCapacities.reduce((sum, val) => sum + val, 0);
				const totalCurrent = currentCapacities.reduce((sum, val) => sum + val, 0);

				root.fullDesignCapacity = totalDesign.toFixed(2);
				root.currentDesignCapacity = totalCurrent.toFixed(2);
				root.overallBatteryHealth = ((root.fullDesignCapacity / root.currentDesignCapacity)
											 * 100).toFixed(2);
			}
		}
	}
}
