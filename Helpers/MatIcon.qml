import QtQuick

import qs.Data
import qs.Components

Text {
    id: root

    required property string icon

	font.family: Appearance.fonts.family_Material
	font.weight: Font.Normal
    font.pixelSize: Appearance.fonts.medium
    font.hintingPreference: Font.PreferFullHinting

    antialiasing: true
    verticalAlignment: Text.AlignVCenter
    color: "transparent"
    renderType: Text.NativeRendering
    text: root.icon

    Behavior on color {
        ColAnim {}
    }

    Behavior on opacity {
        NumbAnim {}
    }
}
