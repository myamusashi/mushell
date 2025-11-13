import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Components

StyledRect {
	id: root

	property bool condition: false
	Layout.fillWidth: true
	height: 2
	visible: condition
	color: "transparent"

	StyledRect {
		id: loadingBar

		width: parent.width * 0.3
		height: parent.height
		radius: height / 2
		color: Themes.colors.primary

		SequentialAnimation on color {
			loops: Animation.Infinite

			ColAnim {}
		}

		SequentialAnimation on x {
			loops: Animation.Infinite
			running: root.condition

			NumbAnim {
				from: 0
				to: parent.width - loadingBar.width
				duration: 300
				easing.amplitude: 1.0
				easing.period: 0.5
				easing.type: Easing.OutBounce
			}
			NumbAnim {
				from: parent.width - loadingBar.width
				to: 0
				duration: 300
				easing.amplitude: 1.0
				easing.period: 0.5
				easing.type: Easing.OutBounce
			}
		}
	}
}
