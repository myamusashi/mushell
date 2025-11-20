import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Components

StyledRect {
    Layout.fillHeight: true
    color: "transparent"
    // color: Themes.colors.withAlpha(Themes.m3Colors.background, 0.79)
    implicitWidth: container.width
    radius: 5

    Dots {
        id: container

        MaterialIcon {
            Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
            color: Themes.m3Colors.tertiary
            font.family: Appearance.fonts.familyMono
            font.pointSize: Appearance.fonts.extraLarge * 0.8
            icon: "󱄅"
        }
    }
}
