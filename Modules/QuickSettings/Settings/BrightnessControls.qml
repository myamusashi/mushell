import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Components

RowLayout {
	spacing: Appearance.spacing.normal

	StyledSlide {
		id: brightnessSlider

		Layout.fillWidth: true
		Layout.preferredHeight: 48

		icon: "brightness_5"
		iconSize: Appearance.fonts.large * 1.5
		from: 0
		to: Brightness.maxValue || 1
		value: Brightness.value
		progressBackgroundHeight: 44

		onMoved: debounceTimer.restart()

		Timer {
			id: debounceTimer

			interval: 150
			repeat: false
			onTriggered: Brightness.setBrightness(brightnessSlider.value)
		}
	}

	StyledButton {
		iconButton: "bedtime"
		buttonTitle: "Night mode"
		buttonTextColor: Hyprsunset.isNightModeOn ? Colors.colors.on_primary : Colors.withAlpha(Colors.colors.on_surface, 0.38)
		buttonColor: Hyprsunset.isNightModeOn ? Colors.colors.primary : Colors.withAlpha(Colors.colors.on_surface, 0.1)
		onClicked: Hyprsunset.isNightModeOn ? Hyprsunset.down() : Hyprsunset.up()
	}
}
