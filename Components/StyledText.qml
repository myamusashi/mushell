import QtQuick
import qs.Data

Text {
	id: root

	property alias textContent: root.text

	font.family: Appearance.fonts.family_Sans
	font.pixelSize: Appearance.fonts.medium
	font.hintingPreference: Font.PreferFullHinting

	color: "transparent"
	renderType: Text.NativeRendering
	textFormat: Text.PlainText
	antialiasing: true

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
