pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int value: parseInt(brValue.text.trim())
    property int maxValue: 100
    property bool available: false

    Process {
        id: getBrightnessValue

        command: ["brightnessctl", "g"]
        running: true
        stdout: StdioCollector {
            id: brValue
        }
    }

    Process {
        id: getBrightness

        command: ["brightnessctl", "info"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (let line of lines) {
                    if (line.includes("Current brightness:")) {
                        const match = line.match(/Current brightness:\s*(\d+)\s*\((\d+)%\)/);
                        if (match)
                        root.value = parseInt(match[1]);
                    } else if (line.includes("Max brightness:")) {
                        const match = line.match(/Max brightness:\s*(\d+)/);
                        if (match)
                        root.maxValue = parseInt(match[1]);
                    }
                }
                root.available = true;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.warn("brightnessctl error:", this.text.trim());
                    root.available = false;
                }
            }
        }
    }

    function setBrightness(newValue) {
        if (!root.available)
            return;
        const clampedValue = Math.max(0, Math.min(root.maxValue, Math.round(newValue)));
        setBrightnessProcess.command = ["brightnessctl", "set", clampedValue.toString()];
        setBrightnessProcess.running = true;
        root.value = clampedValue;
    }

    function setBrightnessPercent(percent) {
        if (!root.available)
            return;
        const clampedPercent = Math.max(0, Math.min(100, Math.round(percent)));

        setBrightnessProcess.command = ["brightnessctl", "set", clampedPercent.toString() + "%"];
        setBrightnessProcess.running = true;
    }

    function increaseBrightness(amount) {
        if (!root.available)
            return;
        setBrightnessProcess.command = ["brightnessctl", "set", Math.round(amount).toString() + "%+"];
        setBrightnessProcess.running = true;
    }

    function decreaseBrightness(amount) {
        if (!root.available)
            return;
        setBrightnessProcess.command = ["brightnessctl", "set", Math.round(amount).toString() + "%-"];
        setBrightnessProcess.running = true;
    }

    Process {
        id: setBrightnessProcess
        running: false

        stdout: StdioCollector {}

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "")
                console.warn("Failed to set brightness:", this.text.trim());
            }
        }
    }
}
