import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
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
        buttonTextColor: Hyprsunset.isNightModeOn ? Themes.m3Colors.onPrimary : Themes.withAlpha(Themes.m3Colors.onSurface, 0.38)
        buttonColor: Hyprsunset.isNightModeOn ? Themes.m3Colors.primary : Themes.withAlpha(Themes.m3Colors.onSurface, 0.1)
        onClicked: Hyprsunset.isNightModeOn ? Hyprsunset.down() : Hyprsunset.up()
    }
}
