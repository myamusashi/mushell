import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Configs
import qs.Components

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
            buttonColor: modelData.profile === PowerProfiles.profile ? Themes.m3Colors.primary : Themes.withAlpha(Themes.m3Colors.onSurface, 0.1)
            buttonTextColor: modelData.profile === PowerProfiles.profile ? Themes.m3Colors.onPrimary : Themes.withAlpha(Themes.m3Colors.onSurface, 0.38)
            onClicked: PowerProfiles.profile = modelData.profile
        }
    }
}
