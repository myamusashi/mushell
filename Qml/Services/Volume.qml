pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.States

Singleton {
    property alias linkTracker: linkTracker

    readonly property real sliderHeight: 250 - 30 - 40 - 2 * Appearance.spacing.normal
    readonly property int itemSize: 40
    readonly property int itemSpacing: Appearance.spacing.large

    property bool openPerAppVolume: false

    PwNodeLinkTracker {
        id: linkTracker

        node: Pipewire.defaultAudioSink
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio

        function onVolumeChanged() {
            GlobalStates.showOSD("volume");
        }
    }

    IpcHandler {
        target: "volume"

        function systemGet(): string {
            return JSON.stringify({
                volume: Pipewire.defaultAudioSink.audio.volume,
                muted: Pipewire.defaultAudioSink.audio.muted
            });
        }

        function systemSet(percent: int): void {
            Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Math.min(1.0, percent / 100));
        }

        function systemChange(delta: int): void {
            Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Math.min(1.0, Pipewire.defaultAudioSink.audio.volume + delta / 100));
        }

        function systemMute(): void {
            Pipewire.defaultAudioSink.audio.muted = true;
        }

        function systemUnmute(): void {
            Pipewire.defaultAudioSink.audio.muted = false;
        }

        function systemToggleMute(): void {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }

        function appList(): string {
            const streams = Pipewire.nodes.values.filter(node => node.isStream);
            const streamSummaries = [];
            for (const stream of streams)
                streamSummaries.push({
                    id: stream.id,
                    name: stream.name,
                    appName: stream.properties["application.name"] ?? stream.description ?? stream.name,
                    mediaName: stream.properties["media.name"] ?? "",
                    volume: stream.audio.volume,
                    muted: stream.audio.muted
                });
            return JSON.stringify(streamSummaries);
        }

        function appSet(id: int, percent: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.volume = Math.max(0.0, Math.min(1.0, percent / 100));
        }

        function appChange(id: int, delta: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.volume = Math.max(0.0, Math.min(1.0, stream.audio.volume + delta / 100));
        }

        function appMute(id: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.muted = true;
        }

        function appUnmute(id: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.muted = false;
        }

        function appToggleMute(id: int): void {
            const stream = Pipewire.nodes.values.filter(node => node.isStream).find(node => node.id === id);
            if (stream)
                stream.audio.muted = !stream.audio.muted;
        }
    }
}
