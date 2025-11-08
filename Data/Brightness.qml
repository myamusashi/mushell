pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	property int value: parseInt(brightnessFile.text().trim())
	property int maxValue: parseInt(brightnessMaxFile.text().trim())

	Process {
		command: ["sh", "-c", "echo /sys/class/backlight/*/brightness"]
		running: true
		stdout: StdioCollector {
			id: brPath
		}
	}

	Process {
		command: ["sh", "-c", "echo /sys/class/backlight/*/max_brightness"]
		running: true
		stdout: StdioCollector {
			id: brMaxPath
		}
	}

	FileView {
		id: brightnessFile

		path: brPath.text.split("\n")[0]
		watchChanges: true
		blockLoading: true
		onFileChanged: this.reload()
	}

	FileView {
		id: brightnessMaxFile

		path: brMaxPath.text.trim()
		blockLoading: true
		onFileChanged: this.reload()
	}

	function setBrightness(newValue) {
		if (brightnessPath === "")
			return;
		setBrightnessProcess.command = ["sh", "-c", "echo " + Math.round(newValue) + " > " + brightnessPath];
		setBrightnessProcess.running = true;
	}

	Process {
		id: setBrightnessProcess
		running: false
	}
}
