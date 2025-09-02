import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.Data

Rectangle {
	id: root

	property int maximumWidth: 184
	property int padding: 16

	Layout.fillHeight: true
	Layout.maximumWidth: maximumWidth + padding
	clip: true
	color: Appearance.colors.withAlpha(Appearance.colors.background, 0.79)
	implicitWidth: windowNameText.contentWidth + padding
	radius: 5

	Behavior on implicitWidth {
		NumberAnimation {
			duration: Appearance.animations.durations.small
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
		}
	}

	Text {
		id: windowNameText

		property string actWinName: activeWindow?.activated ? activeWindow?.appId : "desktop"
		readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

		anchors.centerIn: parent
		color: Appearance.colors.on_primary_container
		elide: Text.ElideMiddle
		font.pointSize: 11
		horizontalAlignment: Text.AlignHCenter
		text: actWinName
		width: (contentWidth > root.maximumWidth) ? root.maximumWidth : undefined
	}
}
