import QtQuick
import qs.Data

Text {
	id: root

	property alias textContent: root.text

	font.family: Appearance.fonts.family_Sans
	font.pixelSize: Appearance.fonts.medium
	font.hintingPreference: Font.PreferVerticalHinting
	font.letterSpacing: -0.2
	font.kerning: true
	renderType: Text.NativeRendering

	color: "transparent"
	textFormat: Text.PlainText
	antialiasing: true

	smooth: true

	verticalAlignment: Text.AlignVCenter
	horizontalAlignment: Text.AlignLeft

	elide: Text.ElideRight
	wrapMode: Text.NoWrap

	Behavior on color {
		ColAnim {}
	}

	Behavior on opacity {
		NumbAnim {}
	}

	Behavior on font.pixelSize {
		NumbAnim {}
	}
}
