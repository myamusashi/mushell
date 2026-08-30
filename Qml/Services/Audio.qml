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

    // Mirrors the AudioCardsModel backing object; values are AudioCard* instances.
    readonly property var cards: AudioProfilesWatcher.cards

    // Exposed so consumers (and our own signal handler) can observe a single
    // boolean even though the source of truth now lives on AudioProfilesWatcher.
    readonly property bool audioConnected: AudioProfilesWatcher.connected

    // Pick the AudioCard that backs Pipewire's current default sink. Falls back
    // to the first card so the Quick Settings drawer still has a profile to show
    // when the user hasn't selected anything yet.
    readonly property var defaultSinkCard: {
        if (!cards)
            return null;
        const all = cards.count();
        if (all <= 0)
            return null;
        const sink = Pipewire.defaultAudioSink;
        if (sink) {
            for (let i = 0; i < all; i++) {
                const c = cards.card(i);
                if (c && c.deviceId === sink.id)
                    return c;
            }
        }
        return cards.card(0);
    }

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
        if (savedSink && cards) {
            for (let i = 0; i < cards.count(); i++) {
                const c = cards.card(i);
                if (c && c.name === savedSink) {
                    AudioDevicesWatcher.setDefaultSink(c.name);
                    break;
                }
            }
        }
        profileRestoreDelay.start();
    }

    function restoreProfiles() {
        const profiles = Configs.audio.sinkProfiles;
        if (!profiles || typeof profiles !== "object" || !cards)
            return;
        const total = cards.count();
        if (total <= 0)
            return;

        for (let i = 0; i < total; i++) {
            const card = cards.card(i);
            if (!card || !card.name)
                continue;
            const savedIndex = profiles[card.name];
            if (savedIndex === undefined || savedIndex < 0)
                continue;
            const deviceId = card.deviceId;
            if (!deviceId)
                continue;
            const model = card.profiles;
            for (let j = 0; j < model.count(); j++) {
                const p = model.get(j);
                if (p.index === savedIndex && p.available === "yes") {
                    AudioProfilesWatcher.setProfile(deviceId, p.index);
                    break;
                }
            }
        }
    }

    function getIcon(node) {
        return node.isSink ? getSinkIcon(node) : getSourceIcon(node);
    }

    function getSinkIcon(node) {
        if (node.audio.muted)
            return "volume_off";
        if (node.audio.volume > 0.5)
            return "volume_up";
        if (node.audio.volume > 0.01)
            return "volume_down";
        return "volume_mute";
    }

    function getSourceIcon(node) {
        return node.audio.muted ? "mic_off" : "mic";
    }

    function toggleMute(node) {
        node.audio.muted = !node.audio.muted;
    }

    function wheelAction(event, node) {
        const delta = event.angleDelta.y < 0 ? -0.01 : 0.01;
        node.audio.volume = Math.max(0.0, Math.min(1.3, node.audio.volume + delta));
    }

    IpcHandler {
        target: "audio"
        function deviceList() {
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
        function deviceSet(name) {
            AudioDevicesWatcher.setDefaultSink(name);
        }
        function profileList() {
            const card = root.defaultSinkCard;
            if (!card)
                return JSON.stringify({
                    deviceId: 0,
                    deviceName: "",
                    activeIndex: -1,
                    profiles: []
                });

            const m = card.profiles;
            const count = m.count();
            const r = {
                deviceId: card.deviceId,
                deviceName: card.name,
                activeIndex: card.activeIndex,
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
        function profileSet(name) {
            const card = root.defaultSinkCard;
            if (!card)
                return;

            const match = card.profiles.find(p => p.name === name);
            if (!match)
                return;

            AudioProfilesWatcher.setProfile(card.deviceId, match.index);
        }
    }
}
