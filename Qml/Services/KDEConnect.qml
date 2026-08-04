pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs

Singleton {
    id: root

    property var allDevices: []
    property var availableDevices: []
    property int pollInterval: 15000
    property bool polling: true
    property string myDeviceId: ""

    readonly property bool hasAvailableDevices: availableDevices.length > 0
    readonly property bool hasDevices: allDevices.length > 0

    function refresh() {
        discoverCommand.running = true;
    }

    function shareFile(deviceId, path) {
        if (!deviceId || !path)
            return;
        const p = shareFileProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--share", path]
        });
        p.running = true;
    }

    function shareText(deviceId, text) {
        if (!deviceId || !text)
            return;
        const p = shareTextProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--share-text", text]
        });
        p.running = true;
    }

    function sendClipboard(deviceId) {
        if (!deviceId)
            return;
        const p = clipboardProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--send-clipboard"]
        });
        p.running = true;
    }

    function ping(deviceId, message) {
        if (!deviceId)
            return;
        const args = ["kdeconnect-cli", "-d", deviceId];
        if (message)
            args.push("--ping-msg", message);
        else
            args.push("--ping");
        const p = pingProcess.createObject(root, {
            command: args
        });
        p.running = true;
    }

    function ring(deviceId) {
        if (!deviceId)
            return;
        const p = ringProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--ring"]
        });
        p.running = true;
    }

    function lockDevice(deviceId) {
        if (!deviceId)
            return;
        const p = lockProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--lock"]
        });
        p.running = true;
    }

    function unlockDevice(deviceId) {
        if (!deviceId)
            return;
        const p = unlockProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--unlock"]
        });
        p.running = true;
    }

    function pair(deviceId) {
        if (!deviceId)
            return;
        const p = pairProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--pair"]
        });
        p.running = true;
    }

    function unpair(deviceId) {
        if (!deviceId)
            return;
        const p = unpairProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--unpair"]
        });
        p.running = true;
    }

    function sendSms(deviceId, message, destination) {
        if (!deviceId || !message || !destination)
            return;
        const p = smsProcess.createObject(root, {
            command: ["kdeconnect-cli", "-d", deviceId, "--send-sms", message, "--destination", destination]
        });
        p.running = true;
    }

    function deviceById(id) {
        for (const d of root.allDevices) {
            if (d.id === id)
                return d;
        }
        return null;
    }

    function deviceByName(name) {
        for (const d of root.allDevices) {
            if (d.name === name)
                return d;
        }
        return null;
    }

    function parseDeviceList(text) {
        const lines = text.trim().split("\n").filter(l => l.trim() !== "");
        const result = [];
        for (const line of lines) {
            const match = line.match(/^(\S+)\s+(.+)$/);
            if (match)
                result.push({
                    id: match[1],
                    name: match[2].trim()
                });
        }
        return result;
    }

    function parseFullDeviceList(text) {
        const lines = text.trim().split("\n").filter(l => l.trim() !== "");
        const result = [];
        for (const line of lines) {
            const match = line.match(/^-\s+(.+?):\s+(\S+)\s+(.+)$/);
            if (match)
                result.push({
                    name: match[1],
                    id: match[2],
                    info: match[3].trim()
                });
        }
        return result;
    }

    Timer {
        id: pollTimer
        interval: Configs.kdeConnect.pollInterval
        running: Configs.kdeConnect.pollingEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: myIdProcess
        command: ["kdeconnect-cli", "--my-id"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.myDeviceId = text.trim();
            }
        }
    }

    Process {
        id: discoverCommand
        command: ["kdeconnect-cli", "--refresh"]
        onExited: { // qmllint disable
            listAvailable.running = true;
            listAll.running = true;
        }
    }

    Process {
        id: listAvailable
        command: ["kdeconnect-cli", "--list-available", "--id-name-only"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.availableDevices = root.parseDeviceList(text);
            }
        }
    }

    Process {
        id: listAll
        command: ["kdeconnect-cli", "--list-devices", "--id-name-only"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.allDevices = root.parseDeviceList(text);
            }
        }
    }

    Component {
        id: shareFileProcess
        Process {
            stderr: StdioCollector {
                id: stdShareFileProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] shareFile failed:", stdShareFileProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: shareTextProcess
        Process {
            stderr: StdioCollector {
                id: stdShareTextProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] shareText failed:", stdShareTextProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: clipboardProcess
        Process {
            stderr: StdioCollector {
                id: stdClipboardProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] sendClipboard failed:", stdClipboardProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: pingProcess
        Process {
            stderr: StdioCollector {
                id: stdPingProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] ping failed:", stdPingProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: ringProcess
        Process {
            stderr: StdioCollector {
                id: stdRingProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] ring failed:", stdRingProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: lockProcess
        Process {
            stderr: StdioCollector {
                id: stdLockProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] lock failed:", stdLockProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: unlockProcess
        Process {
            stderr: StdioCollector {
                id: stdUnlockProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] unlock failed:", stdUnlockProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: pairProcess
        Process {
            stderr: StdioCollector {
                id: stdPairProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] pair failed:", stdPairProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: unpairProcess
        Process {
            stderr: StdioCollector {
                id: stdUnpairProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] unpair failed:", stdUnpairProcess.text);
                destroy();
            }
        }
    }

    Component {
        id: smsProcess
        Process {
            stderr: StdioCollector {
                id: stdSmsProcess
            }
            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] sendSms failed:", stdSmsProcess.text);
                destroy();
            }
        }
    }
}
