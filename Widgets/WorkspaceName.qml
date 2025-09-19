import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import qs.Data
import qs.Components

Rectangle {
	id: root


	Layout.fillHeight: true
	clip: true
	// color: Appearance.colors.withAlpha(Appearance.colors.background, 0.79)
	color: "transparent"
	implicitWidth: windowNameText.contentWidth
	radius: 5

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
		color: Appearance.colors.on_primary_container
		elide: Text.ElideMiddle
		font.pixelSize: Appearance.fonts.medium
		horizontalAlignment: Text.AlignHCenter
		text: actWinName.toUpperCase()
	}
}
