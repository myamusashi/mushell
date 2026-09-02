pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/screenshot"

    signal notify(string summary, string body, string urgency, string icon, string app, var actions)

    // Forward shared Screenshotter's notify to wrapper's notify -> sendNotification
    Connections {
        target: internal
        function onNotify(summary, body, urgency, icon, app, actions) {
            root.notify(summary, body, urgency, icon, app, actions);
        }
    }
    Connections {
        target: root
        function onNotify(summary, body, urgency, icon, app, actions) {
            root.sendNotification(summary, body, urgency, icon, app, actions);
        }
    }

    // Shared screenshot/selection/window-picker logic
    PanelScreenshot {
        id: internal

        screenshotDir: root.screenshotDir
    }

    // Public API delegating to shared
    function screenshotWindow(action) {
        internal.screenshotWindow(action);
    }
    function screenshotSelection(action) {
        internal.screenshotSelection(action);
    }
    function screenshotOutput(target, action) {
        internal.screenshotOutput(target, action);
    }
    function screenshotAllOutputs(action) {
        internal.screenshotAllOutputs(action);
    }
    function pickWindowForRecord(callback) {
        internal.pickWindowForRecord(callback);
    }
    function getMonitors(callback) {
        internal.getMonitors(callback);
    }
    function freezeAllScreens(callback) {
        internal.freezeAllScreens(callback);
    }
    function copyToClipboard(img) {
        internal.copyToClipboard(img);
    }

    // Notification helper for actions (Open / Show in Folder)
    Process {
        id: actionProcess
        property string filePath: ""
        property string dirPath: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const action = text.trim();
                const target = action === "folder" ? actionProcess.dirPath : actionProcess.filePath;
                if ((action === "open" || action === "folder" || action === "default") && target)
                    Quickshell.execDetached({
                        command: ["xdg-open", target]
                    });
            }
        }
    }

    function sendNotification(summary, body, urgency, icon, app, actions) {
        const args = ["notify-send", "-a", app || "screengrab"];
        if (urgency && urgency !== "normal")
            args.push("-u", urgency);
        if (icon)
            args.push("-i", icon);
        const hasActions = actions && actions.length > 0;
        if (hasActions) {
            args.push("--wait");
            for (let i = 0; i < actions.length; i++)
                args.push("--action=" + actions[i].id + "=" + actions[i].label);
        }
        args.push(summary, body);
        if (!hasActions) {
            Quickshell.execDetached({
                command: args
            });
            return;
        }
        actionProcess.filePath = body;
        actionProcess.dirPath = body.substring(0, Math.max(body.lastIndexOf("/"), 0)) || "/";
        actionProcess.command = args;
        actionProcess.running = true;
    }
}
