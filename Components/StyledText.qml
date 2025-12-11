import QtQuick

import qs.Configs

Text {
    font.family: Appearance.fonts.familySans
    font.pixelSize: Appearance.fonts.medium
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
