import QtQuick
import qs.Data

Text {
    font.family: Appearance.fonts.family_Sans
    font.pixelSize: Appearance.fonts.medium
    font.hintingPreference: Font.PreferFullHinting
    font.letterSpacing: 0
    renderType: Text.NativeRendering
    color: "transparent"
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    
    Behavior on color {
        ColAnim {}
    }
}
