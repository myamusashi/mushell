import QtQuick
import QtQuick.Controls

import qs.Data
import qs.Helpers

Switch {
	id: root

	indicator: StyledRect {
		implicitWidth: 52
		implicitHeight: 32
		x: root.leftPadding
		y: parent.height / 2 - height / 2
		radius: Appearance.rounding.full
		color: root.checked ? Colors.colors.primary : Colors.colors.surface_container_highest
		border.width: 2
		border.color: Colors.colors.outline

		StyledRect {
			id: handle

			property int horizontalMargin: 5

			x: root.checked ? parent.width - width - horizontalMargin - -3 : horizontalMargin
			y: (parent.height - height) / 2
			width: root.down ? 24 : root.checked ? 24 : 16
			height: root.down ? 28 : root.checked ? 24 : 16
			radius: Appearance.rounding.full
			color: root.down ? Colors.colors.on_primary : root.checked ? Colors.colors.on_primary : Colors.colors.outline

			MatIcon {
				icon: "check"
				color: root.checked ? Colors.colors.on_background : Colors.colors.surface_container_highest
				visible: root.checked ? true : false
				font.pixelSize: Appearance.fonts.large
				anchors.centerIn: handle
			}

			Behavior on x {
				NumbAnim {
					easing.type: Easing.Bezier
					easing.bezierCurve: Appearance.animations.curves.emphasized
					duration: Appearance.animations.durations.small
				}
			}
			Behavior on height {
				NumbAnim {
					easing.type: Easing.Bezier
					easing.bezierCurve: Appearance.animations.curves.emphasized
					duration: Appearance.animations.durations.small
				}
			}
			Behavior on width {
				NumbAnim {
					easing.type: Easing.Bezier
					easing.bezierCurve: Appearance.animations.curves.emphasized
					duration: Appearance.animations.durations.small
				}
			}
		}
	}
}
