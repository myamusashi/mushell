import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Data
import qs.Components

RowLayout {
	spacing: Appearance.spacing.small

	readonly property var profiles: [
		{
			icon: "energy_savings_leaf",
			name: "Power save",
			profile: PowerProfile.PowerSaver
		},
		{
			icon: "balance",
			name: "Balanced",
			profile: PowerProfile.Balanced
		},
		{
			icon: "rocket_launch",
			name: "Performance",
			profile: PowerProfile.Performance
		}
	]

	Repeater {
		model: parent.profiles

		delegate: StyledButton {
			required property var modelData

			iconButton: modelData.icon
			buttonTitle: modelData.name
			buttonColor: modelData.profile === PowerProfiles.profile ? Colors.colors.primary : Colors.withAlpha(Colors.colors.on_surface, 0.1)
			buttonTextColor: modelData.profile === PowerProfiles.profile ? Colors.colors.on_primary : Colors.withAlpha(Colors.colors.on_surface, 0.38)
			onClicked: PowerProfiles.profile = modelData.profile
		}
	}
}
