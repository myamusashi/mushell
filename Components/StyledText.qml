import QtQuick

import qs.Configs

Text {
    font.family: Appearance.fonts.family.sans
    font.pixelSize: Appearance.fonts.size.medium
    font.hintingPreference: Font.PreferFullHinting
    font.letterSpacing: 0
    renderType: Text.NativeRendering
    color: "transparent"
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight

    Behavior on color {
        CAnim {}
    }
}
