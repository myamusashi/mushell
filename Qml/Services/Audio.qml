pragma ComponentBehavior: Bound
pragma Singleton

import Vast.Audio
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs.Core.Configs

Singleton {
    id: root

    readonly property var listSink: Pipewire.nodes.values.filter(e => e.isSink && !e.isStream).map(e => ({
                nodeId: e.id,
                name: e.name,
                description: e.description
            }))
    // Numeric PipeWire device ID (quint32, 0 while disconnected)
    readonly property int idPipewire: AudioProfilesWatcher.deviceId
    // Index of the currently active profile (-1 if unknown)
    readonly property int activeProfileIndex: AudioProfilesWatcher.activeIndex
    readonly property var activeProfiles: {
        const ap = AudioProfilesWatcher.activeProfile;
        return (ap && ap.index >= 0) ? [ap] : [];
    }
    // Roles: index, name, description, available, readable
    readonly property var models: AudioProfilesWatcher.profiles
    readonly property bool audioConnected: AudioProfilesWatcher.connected

    property bool restartPending: false
    property bool wasAudioConnected: false
    property bool restoringAudioState: false

    Component.onCompleted: {
        if (audioConnected && !restoringAudioState) {
            wasAudioConnected = true;
            restoreTimer.start();
        }
    }

    onAudioConnectedChanged: {
        if (audioConnected && !wasAudioConnected && !restoringAudioState) {
            wasAudioConnected = true;
            restoreTimer.start();
        }
        if (!audioConnected) {
            wasAudioConnected = false;
            if (restoringAudioState) {
                restoreTimer.stop();
                profileRestoreDelay.stop();
                restoringAudioState = false;
            }
        }
    }

    Timer {
        id: restoreTimer
        interval: 1000
        repeat: false
        onTriggered: root.restoreAudioState()
    }

    Timer {
        id: profileRestoreDelay
        interval: 1500
        repeat: false
        onTriggered: {
            root.restoreProfiles();
            root.restoringAudioState = false;
        }
    }

    function restoreAudioState() {
        if (restoringAudioState)
            return;
        restoringAudioState = true;
        const savedSink = Configs.audio.defaultSinkName;
        if (savedSink) {
            const sink = root.listSink.find(s => s.name === savedSink);
            if (sink) {
                Quickshell.execDetached({
                    command: ["wpctl", "set-default", sink.nodeId]
                });
            }
        }
        profileRestoreDelay.start();
    }

    function restoreProfiles() {
        const profiles = Configs.audio.sinkProfiles;
        if (!profiles || typeof profiles !== "object")
            return;
        const device = AudioProfilesWatcher.deviceName;
        if (!device)
            return;
        const savedIndex = profiles[device];
        if (savedIndex === undefined || savedIndex < 0)
            return;
        const deviceId = AudioProfilesWatcher.deviceId;
        if (!deviceId)
            return;
        const model = AudioProfilesWatcher.profiles;
        for (let i = 0; i < model.count(); i++) {
            const p = model.get(i);
            if (p.index === savedIndex && p.available === "yes") {
                Quickshell.execDetached({
                    command: ["pw-cli", "set-param", String(deviceId), "Profile", `{ "index": ${p.index} }`]
                });
                break;
            }
        }
    }

    function getIcon(node: PwNode): string {
        return node.isSink ? getSinkIcon(node) : getSourceIcon(node);
    }

    function getSinkIcon(node: PwNode): string {
        if (node.audio.muted)
            return "volume_off";
        if (node.audio.volume > 0.5)
            return "volume_up";
        if (node.audio.volume > 0.01)
            return "volume_down";
        return "volume_mute";
    }

    function getSourceIcon(node: PwNode): string {
        return node.audio.muted ? "mic_off" : "mic";
    }

    function toggleMute(node: PwNode) {
        node.audio.muted = !node.audio.muted;
    }

    function wheelAction(event: WheelEvent, node: PwNode) {
        const delta = event.angleDelta.y < 0 ? -0.01 : 0.01;
        node.audio.volume = Math.max(0.0, Math.min(1.3, node.audio.volume + delta));
    }

    IpcHandler {
        target: "audio"
        function deviceList(): string {
            const m = AudioDevicesWatcher.devices;
            const r = [];
            for (let i = 0; i < m.count(); i++) {
                const d = m.get(i);
                r.push({
                    id: d.id,
                    name: d.name,
                    description: d.description,
                    mediaClass: d.mediaClass,
                    state: d.state,
                    isMonitor: d.isMonitor,
                    monitorOf: d.monitorOf
                });
            }
            return JSON.stringify(r);
        }
        function deviceSet(name: string): void {
            Quickshell.execDetached({
                command: ["wpctl", "set-default", name]
            });
        }
        function profileList(): string {
            const m = AudioProfilesWatcher.profiles;
            const count = m.count();
            const r = {
                deviceId: AudioProfilesWatcher.deviceId,
                deviceName: AudioProfilesWatcher.deviceName,
                activeIndex: AudioProfilesWatcher.activeIndex,
                profiles: []
            };
            for (let i = 0; i < count; i++) {
                const p = m.get(i);
                r.profiles.push({
                    index: p.index,
                    name: p.name,
                    description: p.description,
                    available: p.available,
                    readable: p.readable
                });
            }
            return JSON.stringify(r);
        }
        function profileSet(name: string): void {
            Quickshell.execDetached({
                command: ["wpctl", "set-profile", String(AudioProfilesWatcher.deviceId), name]
            });
        }
    }
}
