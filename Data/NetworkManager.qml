pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	property alias networks: v_networks.instances
	property list<string> networkRows: []

	Variants {
		id: v_networks

		model: root.networkRows

		delegate: AccessPoint {
			required property var modelData
			property var net: modelData.split(":")
			active: net[0] === "yes"
			strength: parseInt(net[1])
			frequency: parseInt(net[2].split(" ")[0])
			ssid: net[3]
			bssid: net[4]
			security: net[5]
		}
	}

	Process {
		id: getNetworks
		running: true
		command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
		stdout: StdioCollector {
			onStreamFinished: {
				const netstr = this.text.trim().split("\n");
				netstr.pop();
				root.networkRows = netstr;
			}
		}
	}

	component AccessPoint: QtObject {
		required property string ssid
		required property string bssid
		required property int strength
		required property int frequency
		required property bool active
		required property string security
	}
}
