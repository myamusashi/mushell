pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool isNightModeOn: false

    Process {
        id: hyprsunset

        command: ["sh", "-c", "hyprsunset -t 3000"]
    }

    Process {
        id: killHyprsunset

        command: ["sh", "-c", "kill $(pgrep hyprsunset)"]
    }

    function up(): void {
        root.isNightModeOn = true
        hyprsunset.running = true
    }

    function down(): void {
        root.isNightModeOn = false
        killHyprsunset.running = true
    }
}
