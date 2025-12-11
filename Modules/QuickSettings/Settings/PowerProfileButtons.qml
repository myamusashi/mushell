import QtQuick
import QtQuick.Layouts

import Quickshell.Services.UPower

import qs.Components
import qs.Configs
import qs.Services

RowLayout {
    spacing: Appearance.spacing.small

    readonly property var profiles: [
        {
            "icon": "energy_savings_leaf",
            "name": "Power save",
            "profile": PowerProfile.PowerSaver
        },
        {
            "icon": "balance",
            "name": "Balanced",
            "profile": PowerProfile.Balanced
        },
        {
            "icon": "rocket_launch",
            "name": "Performance",
            "profile": PowerProfile.Performance
        }
    ]

    Repeater {
        model: parent.profiles

        delegate: StyledButton {
            required property var modelData

            iconButton: modelData.icon
            buttonTitle: modelData.name
            enabled: modelData.profile === PowerProfiles.profile
            buttonColor: modelData.profile === PowerProfiles.profile ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.1)
            buttonTextColor: modelData.profile === PowerProfiles.profile ? Colours.m3Colors.m3OnPrimary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.38)
            onClicked: PowerProfiles.profile = modelData.profile
        }
    }
}
