pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isRecordingControlOpen: false
    property int recordingSeconds: 0
    property alias recordingTimer: recordingTimer

    Process {
        id: pidStatusRecording

        command: ["sh", "-c", "cat /tmp/wl-screenrec.pid"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim();
                if (data !== "") {
                    root.isRecordingControlOpen = true;
                } else {
                    root.recordingSeconds = 0;
                    root.isRecordingControlOpen = false;
                }
            }
        }
    }

    Timer {
        id: pidCheckTimer

        interval: 2000
        repeat: true
        running: true
        onTriggered: pidStatusRecording.running = true
    }

    Timer {
        id: recordingTimer

        interval: 1000
        repeat: true
        running: root.isRecordingControlOpen
        onTriggered: root.recordingSeconds++
    }
}
