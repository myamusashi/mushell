pragma Singleton

import QtQuick
import Quickshell

import qs.Core.States
import qs.Core.Utils
import qs.Services.CaptureScreenImage
import qs.Services.CaptureScreenVideo

Singleton {
    id: root

    property var screenshotOptions: ScriptModel {
        values: {
            let options = [
                {
                    "id": "all-monitors",
                    "name": qsTr("All monitors"),
                    "icon": "split_scene_right",
                    "action": () => CaptureScreenImage.screenshotAllOutputs("save+copy")
                },
                {
                    "id": "window",
                    "name": qsTr("Window"),
                    "icon": "select_window_2",
                    "action": () => CaptureScreenImage.screenshotWindow("save+copy")
                },
                {
                    "id": "selection",
                    "name": qsTr("Selection"),
                    "icon": "select",
                    "action": () => CaptureScreenImage.screenshotSelection("save+copy")
                }
            ];

            Quickshell.screens.forEach(screen => {
                options.push({
                    "id": `output-${screen.name}`,
                    "name": screen.name,
                    "icon": "monitor",
                    "action": () => CaptureScreenImage.screenshotOutput(screen.name, "save+copy")
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
                        if (CaptureScreenVideo.isRecording)
                            CaptureScreenVideo.stopRecording();
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
                        if (CaptureScreenVideo.isRecording)
                            CaptureScreenVideo.stopRecording();
                        else
                            CaptureScreenVideo.startRecording("", screen.name);
                    }
                });
            });

            return options;
        }
    }

    function openRegionSelector(): void {
        if (!CaptureScreenVideo.isRecording)
            select.open();
    }

    function startRecording(output: string): void {
        CaptureScreenVideo.startRecording("", output);
    }

    function recordWindow(): void {
        if (CaptureScreenVideo.isRecording) {
            CaptureScreenVideo.stopRecording();
            return;
        }
        GlobalStates.isRecordingPanelOpen = false;
        CaptureScreenImage.pickWindowForRecord(appId => {
            if (appId)
                CaptureScreenVideo.recordToplevel(appId);
        });
    }

    function stopRecording(): void {
        CaptureScreenVideo.stopRecording();
    }

    ScreenSelection {
        id: select

        onGeometrySelected: geo => CaptureScreenVideo.recordSelection(geo)
        onCancelled: {}
    }
}
