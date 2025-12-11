import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQuick.Controls

import Quickshell

import qs.Configs
import qs.Helpers
import qs.Services

TextField {
    id: root

    Material.theme: Material.System
    Material.accent: Colours.m3Colors.m3Primary
    Material.primary: Colours.m3Colors.m3Primary
    Material.background: "transparent"
    Material.foreground: Colours.m3Colors.m3OnSurface
    Material.containerStyle: Material.Outlined
    renderType: Text.QtRendering

    selectedTextColor: Colours.m3Colors.m3OnSecondaryContainer
    selectionColor: Colours.m3Colors.m3SecondaryContainer
    placeholderTextColor: Colours.m3Colors.m3Outline
    wrapMode: TextEdit.Wrap
    clip: true

    font {
        family: Appearance.fonts.family.sans
        pixelSize: Appearance.fonts.size.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: {
            "wght": 450,
            "wdth": 100
        }
    }

    MArea {
        layerColor: "transparent"
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }
}
