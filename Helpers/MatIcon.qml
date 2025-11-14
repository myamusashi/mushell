import QtQuick

import qs.Data
import qs.Components

Text {
    id: root

    required property string icon

    font.family: Appearance.fonts.family_Material
    font.pixelSize: Appearance.fonts.medium
    font.hintingPreference: Font.PreferNoHinting

    antialiasing: true

    horizontalAlignment: Text.AlignHCenter
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
