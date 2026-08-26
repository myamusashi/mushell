pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vast.Audio

import qs.Core.Configs
import qs.Components.Button
import qs.Services

SplitButton {
    id: root

    function profileAt(i) {
        return typeof Audio.models.get === "function" ? Audio.models.get(i) : Audio.models[i];
    }
    readonly property int profileCount: typeof Audio.models.count === "function" ? Audio.models.count() : Audio.models.count ?? Audio.models.length ?? 0
    leadingFillsWidth: true

    readonly property int selectedIndex: {
        for (let i = 0; i < root.profileCount; ++i) {
            const profile = root.profileAt(i);
            if (profile && profile.index === Audio.activeProfileIndex)
                return i;
        }

        return -1;
    }

    readonly property string selectedLabel: {
        const profile = root.selectedIndex >= 0 ? root.profileAt(root.selectedIndex) : null;
        return profile ? profile.readable : "";
    }

    model: Audio.models
    textRole: "readable"
    currentIndex: root.selectedIndex
    text: root.selectedLabel
    isItemEnabled: md => md.available === "yes"
    disabledLabel: md => qsTr("N/A")

    onMenuItemActivated: rowIndex => {
        const profile = root.profileAt(rowIndex);
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
