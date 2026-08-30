pragma Singleton

import QtQuick
import Quickshell

import qs.Core.States
import qs.Core.Utils
import qs.Services.ScreenRecorder

Singleton {
    id: root

    property var screenshotOptions: ScriptModel {
        values: {
            let options = [
                {
                    "id": "all-monitors",
                    "name": qsTr("All monitors"),
                    "icon": "split_scene_right",
                    "action": () => ScreenRecorder.screenshotAllOutputs("save+copy")
                },
                {
                    "id": "window",
                    "name": qsTr("Window"),
                    "icon": "select_window_2",
                    "action": () => ScreenRecorder.screenshotWindow("save+copy")
                },
                {
                    "id": "selection",
                    "name": qsTr("Selection"),
                    "icon": "select",
                    "action": () => ScreenRecorder.screenshotSelection("save+copy")
                }
            ];

            Quickshell.screens.forEach(screen => {
                options.push({
                    "id": `output-${screen.name}`,
                    "name": screen.name,
                    "icon": "monitor",
                    "action": () => ScreenRecorder.screenshotOutput(screen.name, "save+copy")
                });
            });

            return options;
        }
    }

    property var recordOptions: ScriptModel {
        values: {
            let options = [
                {
                    "id": "record-selection",
                    "name": qsTr("Selection"),
                    "icon": "select",
                    "action": () => {
                        if (ScreenRecorder.isRecording)
                            ScreenRecorder.stopRecording();
                        else
                            select.open();
                    }
                }
            ];

            Quickshell.screens.forEach(screen => {
                options.push({
                    "id": `record-output-${screen.name}`,
                    "name": screen.name,
                    "icon": "monitor",
                    "action": () => {
                        if (ScreenRecorder.isRecording)
                            ScreenRecorder.stopRecording();
                        else
                            ScreenRecorder.startRecording("", screen.name);
                    }
                });
            });

            return options;
        }
    }

    function openRegionSelector(): void {
        if (!ScreenRecorder.isRecording)
            select.open();
    }

    function startRecording(output: string): void {
        ScreenRecorder.startRecording("", output);
    }

    function recordWindow(): void {
        if (ScreenRecorder.isRecording) {
            ScreenRecorder.stopRecording();
            return;
        }
        GlobalStates.isRecordingPanelOpen = false;
        ScreenRecorder.pickWindowForRecord(appId => {
            if (appId)
                ScreenRecorder.recordToplevel(appId);
        });
    }

    function stopRecording(): void {
        ScreenRecorder.stopRecording();
    }

    ScreenSelection {
        id: select

        onGeometrySelected: geo => ScreenRecorder.recordSelection(geo)
        onCancelled: {}
    }
}
