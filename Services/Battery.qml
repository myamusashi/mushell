pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property bool charging: UPower.displayDevice.state == UPowerDeviceState.Charging
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

        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/energy_full_design && cat /sys/class/power_supply/BAT*/energy_full"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                const values = lines.map(line => parseInt(line));

                const designCapacities = [];
                const currentCapacities = [];

                for (var i = 0; i < values.length; i++) {
                    if (i % 2 === 0)
                    designCapacities.push(values[i]);
                    else
                    currentCapacities.push(values[i]);
                }

                const totalDesign = designCapacities.reduce((sum, val) => sum + val, 0);
                const totalCurrent = currentCapacities.reduce((sum, val) => sum + val, 0);

                root.fullDesignCapacity = totalDesign.toFixed(2);
                root.currentDesignCapacity = totalCurrent.toFixed(2);
                root.overallBatteryHealth = ((root.fullDesignCapacity / root.currentDesignCapacity) * 100).toFixed(2);
            }
        }
    }
}
