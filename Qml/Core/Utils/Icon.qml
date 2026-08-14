import QtQuick

import qs.Core.Configs

Text {
    id: root

    enum IconType {
        Material,
        Weather
    }

    property alias icon: root.text
    readonly property var fontFamilies: [Appearance.fonts.family.material, "Weather Icons"]
    property int type: Icon.Material

    antialiasing: true
    color: "transparent"
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    font {
        family: root.type === Icon.Weather ? "Weather Icons" : Appearance.fonts.family.material
        hintingPreference: Font.PreferFullHinting
        variableAxes: ({
                "opsz": 24,
                "wght": 400
            })
    }
}
