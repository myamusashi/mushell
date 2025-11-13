pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import qs.Data
import qs.Components

StyledRect {
	id: root

	Layout.fillHeight: true
	color: "transparent"
	implicitWidth: windowNameText.contentWidth

	Behavior on implicitWidth {
		NumbAnim {
			duration: Appearance.animations.durations.small
			easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
		}
	}

	StyledText {
		id: windowNameText

		property string actWinName: activeWindow?.activated ? activeWindow?.appId : "desktop"
		readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

		anchors.centerIn: parent
		color: Themes.colors.on_background
		elide: Text.ElideMiddle
		font.weight: Font.Light
		font.pixelSize: Appearance.fonts.large
		horizontalAlignment: Text.AlignHCenter
		text: actWinName.toUpperCase()
	}
}
