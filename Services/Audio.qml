pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property var models: []
    property var activeProfiles: []
    property int idPipewire: 0
    property int activeProfileIndex: activeProfiles.length > 0 ? activeProfiles[0].index : -1

    function getIcon(node: PwNode): string {
        return (node.isSink) ? getSinkIcon(node) : getSourceIcon(node);
    }

    function getSinkIcon(node: PwNode): string {
        return (node.audio.muted) ? "volume_off" : (node.audio.volume > 0.5) ? "volume_up" : (node.audio.volume > 0.01) ? "volume_down" : "volume_mute";
    }

    function getSourceIcon(node: PwNode): string {
        return (node.audio.muted) ? "mic_off" : "mic";
    }

    function toggleMute(node: PwNode) {
        node.audio.muted = !node.audio.muted;
    }

    function wheelAction(event: WheelEvent, node: PwNode) {
        if (event.angleDelta.y < 0)
            node.audio.volume -= 0.01;
        else
            node.audio.volume += 0.01;

        if (node.audio.volume > 1.3)
            node.audio.volume = 1.3;

        if (node.audio.volume < 0)
            node.audio.volume = 0.0;
    }

    function formatProfileName(name) {
        if (name === "off")
            return "Off";
        if (name === "pro-audio")
            return "Pro Audio";

        const parts = name.split("+");
        const formatted = [];

        for (let part of parts) {
            part = part.trim();

            // Remove prefixes
            part = part.replace(/^output:/, "").replace(/^input:/, "");

            // Replace hyphens with spaces and capitalize
            part = part.split("-").map(word => {
                return word.charAt(0).toUpperCase() + word.slice(1);
            }).join(" ");

            formatted.push(part);
        }

        return formatted.join(" + ");
    }

    Process {
        id: profiles

        command: ["sh", "-c", "pw-dump | jq '[.[] | select(.type == \"PipeWire:Interface:Device\") | {id: .id, name: .info.props[\"device.name\"], profiles: .info.params.EnumProfile}][0].profiles'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const trimmed = text.trim();
                    if (!trimmed || trimmed === "null") {
                        root.models = [];
                        return;
                    }

                    const data = JSON.parse(trimmed);
                    if (data && Array.isArray(data)) {
                        root.models = data.map(profile => ({
                                    "index": profile.index,
                                    "name": profile.name,
                                    "description": profile.description,
                                    "available": profile.available,
                                    "readable": root.formatProfileName(profile.name)
                                }));
                    } else
                        root.models = [];
                } catch (e) {
                    console.error("Failed to parse profiles:", e);
                    root.models = [];
                }
            }
        }
    }

    Process {
        id: pipewireId

        command: ["sh", "-c", "pw-dump | jq -r '[.[] | select(.type == \"PipeWire:Interface:Device\") | {id, profiles: .info.params.EnumProfile} | select(.profiles != null and .profiles != []) | .id][]'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim();
                root.idPipewire = data;
            }
        }
    }

    Process {
        id: activeProfiles

        command: ["sh", "-c", "pw-dump | jq '[.[] | select(.type == \"PipeWire:Interface:Device\") | {id: .id, name: .info.props[\"device.name\"], active_profile: .info.params.Profile}].[].active_profile'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const data = JSON.parse(text.trim());
                root.activeProfiles = data.map(active => {
                    return {
                        "index": active.index,
                        "name": active.name,
                        "description": active.description,
                        "available": active.available,
                        "save": active.save
                    };
                });
                root.activeProfileIndex = data.length > 0 ? data[0].index : -1;
            }
        }
    }
}
