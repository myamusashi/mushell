pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isNightModeOn: false

    function up(): void {
        root.isNightModeOn = true;
        hyprsunset.running = true;
    }

    function down(): void {
        root.isNightModeOn = false;
        killHyprsunset.running = true;
    }

    Process {
        id: hyprsunset

        command: ["sh", "-c", "hyprsunset -t 3000"]
    }

    Process {
        id: killHyprsunset

        command: ["sh", "-c", "kill $(pgrep hyprsunset)"]
    }
}
