import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    Layout.fillHeight: true
    color: "transparent"
    // color: Colours.colors.withAlpha(Colours.m3Colors.m3Background, 0.79)
    implicitWidth: container.width
    radius: 5

    Dots {
        id: container

        MaterialIcon {
            Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
            color: Colours.m3Colors.m3Primary
            font.family: Appearance.fonts.familyMono
            font.pointSize: Appearance.fonts.extraLarge * 0.8
            icon: "󱄅"
        }
    }
}
