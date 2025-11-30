import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQuick.Controls
import Quickshell

import qs.Configs
import qs.Helpers

TextField {
    id: root

    Material.theme: Material.System
    Material.accent: Themes.m3Colors.m3Primary
    Material.primary: Themes.m3Colors.m3Primary
	Material.background: "transparent"
    Material.foreground: Themes.m3Colors.m3OnSurface
    Material.containerStyle: Material.Outlined
	renderType: Text.QtRendering

    selectedTextColor: Themes.m3Colors.m3OnSecondaryContainer
    selectionColor: Themes.m3Colors.m3SecondaryContainer
	placeholderTextColor: Themes.m3Colors.m3Outline
	wrapMode: TextEdit.Wrap
    clip: true

    font {
        family: Appearance.fonts.familySans
        pixelSize: Appearance.fonts.small ?? 15
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
