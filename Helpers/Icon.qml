import QtQuick
import qs.Components
import qs.Configs

Text {
    id: root

    enum IconType {
        Lucide,
        Material,
        Weather
    }

    required property string icon

    readonly property string fontFamily: {
        switch (root.type) {
        case Icon.Material:
            return Appearance.fonts.family.material;
        case Icon.Weather:
            return "Weather Icons";
        case Icon.Lucide:
            return "lucide";
        default:
            return Appearance.fonts.family.material;
        }
    }

    property int type: Icon.Material

    antialiasing: true
    color: "transparent"
    renderType: Text.NativeRendering
    text: root.icon

    Behavior on color {
        CAnim {}
    }

    font {
        family: root.fontFamily
        pixelSize: Appearance.fonts.size.medium
        hintingPreference: Font.PreferNoHinting
        variableAxes: {
            "FILL": false,
            "wght": fontInfo.weight,
            "GRAD": 0,
            "opsz": 48
        }
    }
}
