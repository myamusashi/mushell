pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var models: []
    property var activeProfiles: []
    property int idPipewire
    property int activeProfileIndex: activeProfiles.length > 0 ? activeProfiles[0].index : -1

    Process {
        id: profiles

        command: ["sh", "-c", "pw-dump | jq '[.[] | select(.type == \"PipeWire:Interface:Device\") | {id: .id, name: .info.props[\"device.name\"], profiles: .info.params.EnumProfile}][0].profiles'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const data = JSON.parse(text.trim())
                root.models = data.map(profile => {
                                           return {
                                               "index": profile.index,
                                               "name": profile.name,
                                               "description": profile.description,
                                               "available": profile.available,
                                               "readable": formatProfileName(
                                                               profile.name)
                                           }
                                       })
            }
        }
    }

    Process {
        id: pipewireId

        command: ["sh", "-c", "pw-dump | jq -r '[.[] | select(.type == \"PipeWire:Interface:Device\") | {id, profiles: .info.params.EnumProfile} | select(.profiles != null and .profiles != []) | .id][]'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim()
                root.idPipewire = data
            }
        }
    }

    Process {
        id: activeProfiles

        command: ["sh", "-c", "pw-dump | jq '[.[] | select(.type == \"PipeWire:Interface:Device\") | {id: .id, name: .info.props[\"device.name\"], active_profile: .info.params.Profile}].[0].active_profile'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const data = JSON.parse(text.trim())
                root.activeProfiles = data.map(active => {
                                                   return {
                                                       "index": active.index,
                                                       "name": active.name,
                                                       "description": active.description,
                                                       "available": active.available,
                                                       "save": active.save
                                                   }
                                               })
                root.activeProfileIndex = data.length > 0 ? data[0].index : -1
            }
        }
    }

    function formatProfileName(name) {
        if (name === "off")
            return "Off"
        if (name === "pro-audio")
            return "Pro Audio"

        // separate output and input
        const parts = name.split("+")
        const formatted = []

        for (let part of parts) {
            part = part.trim()

            // Remove prefixes
            part = part.replace(/^output:/, "").replace(/^input:/, "")

            // Replace hyphens with spaces and capitalize
            part = part.split("-").map(word => {
                                           return word.charAt(0).toUpperCase(
                                               ) + word.slice(1)
                                       }).join(" ")

            formatted.push(part)
        }

        return formatted.join(" + ")
    }
}
