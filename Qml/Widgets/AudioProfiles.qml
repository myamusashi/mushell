pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Core.Configs
import qs.Components.Button
import qs.Services

SplitButton {
    id: root

    property var card: Audio.defaultSinkCard

    readonly property var resolvedCard: card
    readonly property var profileModel: resolvedCard ? resolvedCard.profiles : null

    function profileAt(i) {
        return profileModel ? profileModel.get(i) : null;
    }

    readonly property int profileCount: profileModel ? profileModel.count() : 0

    readonly property int selectedIndex: {
        if (!resolvedCard)
            return -1;
        for (let i = 0; i < root.profileCount; ++i) {
            const profile = root.profileAt(i);
            if (profile && profile.index === resolvedCard.activeIndex)
                return i;
        }
        return -1;
    }

    readonly property string selectedLabel: {
        const profile = root.selectedIndex >= 0 ? root.profileAt(root.selectedIndex) : null;
        return profile ? profile.readable : "";
    }

    leadingFillsWidth: true
    model: profileModel
    textRole: "readable"
    currentIndex: root.selectedIndex
    text: root.selectedLabel
    isItemEnabled: md => md.available === "yes"
    disabledLabel: md => qsTr("N/A")

    onMenuItemActivated: rowIndex => {
        const profile = root.profileAt(rowIndex);
        if (!profile || profile.available !== "yes" || !resolvedCard)
            return;

        Quickshell.execDetached({
            command: ["pw-cli", "set-param", String(resolvedCard.deviceId), "Profile", `{ "index": ${profile.index} }`]
        });

        const deviceName = resolvedCard.name;
        if (deviceName) {
            const profiles = Configs.audio.sinkProfiles;
            const copied = Object.assign({}, profiles || {});
            copied[deviceName] = profile.index;
            Configs.audio.sinkProfiles = copied;
        }
    }
}
