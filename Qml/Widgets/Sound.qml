pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "../Components/Base"

StyledRect {
    id: root

    readonly property PwNode node: Pipewire.defaultAudioSink

    implicitWidth: container.width
    implicitHeight: parent.height
    color: "transparent"
    radius: Appearance.rounding.small

    Behavior on implicitWidth {
        NAnim {}
    }

    PwObjectTracker {
        objects: [root.node]
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
            const streams = Pipewire.nodes.values.filter(n => n.isStream);
            const r = [];
            for (const s of streams)
                r.push({
                    id: s.id,
                    name: s.name,
                    appName: s.properties["application.name"] ?? s.description ?? s.name,
                    mediaName: s.properties["media.name"] ?? "",
                    volume: s.audio.volume,
                    muted: s.audio.muted
                });
            return JSON.stringify(r);
        }
        function appSet(id: int, percent: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.volume = Math.max(0.0, Math.min(1.0, percent / 100));
        }
        function appMute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = true;
        }
        function appUnmute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = false;
        }
        function appToggleMute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = !s.audio.muted;
        }
    }

    Dots {
        id: container

        spacing: Appearance.spacing.small

        Icon {
            type: Icon.Material
            color: Colours.m3Colors.m3OnBackground
            icon: Audio.getIcon(root.node)
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.fonts.size.large * 1.5
        }

        StyledText {
            color: Colours.m3Colors.m3OnBackground
            text: (root.node.audio.volume * 100).toFixed(0) + "%"
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.fonts.size.medium
        }
    }

    MArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.LeftButton
        onWheel: mevent => Audio.wheelAction(mevent, root.node)
        onClicked: mevent => {
            if (mevent.button === Qt.MiddleButton)
                Audio.toggleMute(root.node);
            else if (mevent.button === Qt.LeftButton)
                GlobalStates.toggleOSD("volume");
        }
    }
}
