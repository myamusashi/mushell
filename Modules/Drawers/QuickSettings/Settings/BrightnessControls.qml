import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Services

RowLayout {
    spacing: Appearance.spacing.normal

    StyledSlide {
        id: brightnessSlider

        Layout.fillWidth: true
        Layout.preferredHeight: 48

        icon: "brightness_5"
        iconSize: Appearance.fonts.size.large * 1.5
        to: Brightness.maxValue || 1
        value: Brightness.value

        onMoved: debounceTimer.restart()

        Timer {
            id: debounceTimer

            interval: 150
            repeat: true
            running: true
            onTriggered: Brightness.setBrightness(brightnessSlider.value)
        }
    }

    StyledButton {
        iconButton: "bedtime"
        buttonTitle: "Night mode"
        buttonTextColor: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3OnPrimary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.38)
        buttonColor: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.1)
        onClicked: Hyprsunset.isNightModeOn ? Hyprsunset.down() : Hyprsunset.up()
        enabled: Hyprsunset.isNightModeOn
    }
}
