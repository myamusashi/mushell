pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vast.Audio

import qs.Core.Configs
import qs.Services

import qs.Components.Menu

DropdownField {
    model: Audio.models
    textRole: "readable"
    valueRole: "index"
    currentValue: Audio.activeProfileIndex
    isItemEnabled: md => md.available === "yes"
    disabledLabel: md => qsTr("N/A")
    isItemActive: (md, _) => md.index === Audio.activeProfileIndex
    onActivated: rowIndex => {
        const profile = Audio.models.get(rowIndex);
        if (!profile || profile.available !== "yes")
            return;

        Quickshell.execDetached({
            command: ["pw-cli", "set-param", String(Audio.idPipewire), "Profile", `{ "index": ${profile.index} }`]
        });

        const deviceName = AudioProfilesWatcher.deviceName;
        if (deviceName) {
            const profiles = Configs.audio.sinkProfiles;
            const copied = Object.assign({}, profiles || {});
            copied[deviceName] = profile.index;
            Configs.audio.sinkProfiles = copied;
        }
    }
}
