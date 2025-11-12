pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Helpers

Slider {
	id: root

	hoverEnabled: true
	Layout.alignment: Qt.AlignHCenter

	property bool dotEnd: true
	property real trackHeightDiff: 15
	property real handleGap: 6
	property real trackDotSize: 4
	property bool useAnim: true
	property int valueWidth
	property int valueHeight
	property string icon
	property int iconSize

	implicitWidth: valueWidth || 200
	implicitHeight: valueHeight || 40

	component TrackDot: StyledRect {
		required property int index
		property real stepValue: root.from + (index * root.stepSize)
		property real normalizedValue: (stepValue - root.from) / (root.to - root.from)
		anchors.verticalCenter: parent.verticalCenter
		x: root.handleGap + (normalizedValue * (parent.width - root.handleGap * 2)) - root.trackDotSize / 2
		width: root.trackDotSize
		height: root.trackDotSize
		radius: Appearance.rounding.normal
		visible: root.dotEnd && index > 0 && index < (root.to - root.from) / root.stepSize
		color: normalizedValue > root.visualPosition ? Colors.colors.on_secondary_container : Colors.colors.on_primary
	}

	MouseArea {
		anchors.fill: parent
		onPressed: mouse => mouse.accepted = false
		cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
	}

	background: Item {
		id: progressItem

		implicitWidth: root.valueWidth || 200
		implicitHeight: root.valueHeight || 40
		width: root.availableWidth
		height: root.availableHeight
		x: root.leftPadding
		y: root.topPadding

		MatIcon {
			anchors {
				left: parent.left
				leftMargin: 10
				verticalCenter: parent.verticalCenter
			}
			icon: root.icon || ""
			color: Colors.colors.on_primary
			font.pixelSize: root.iconSize || 0
			z: 3
		}

		StyledRect {
			id: progressBackground

			anchors {
				verticalCenter: parent.verticalCenter
				left: parent.left
			}
			width: root.handleGap + (root.visualPosition * (parent.width - root.handleGap * 2)) - ((root.pressed ? 1.5 : 3) / 2 + root.handleGap)
			height: parent.height - root.trackHeightDiff
			color: Colors.colors.primary
			radius: Appearance.rounding.normal
			topRightRadius: Appearance.rounding.small * 0.5
			bottomRightRadius: Appearance.rounding.small * 0.5
		}

		StyledRect {
			id: unprogressBackground

			anchors {
				verticalCenter: parent.verticalCenter
				right: parent.right
			}
			width: root.handleGap + ((1 - root.visualPosition) * (parent.width - root.handleGap * 2)) - ((root.pressed ? 1.5 : 3) / 2 + root.handleGap)
			height: parent.height - root.trackHeightDiff
			color: Colors.colors.surface_container_highest
			radius: Appearance.rounding.normal
			topLeftRadius: Appearance.rounding.small * 0.5
			bottomLeftRadius: Appearance.rounding.small * 0.5
		}

		// Track dots
		Repeater {
			model: root.stepSize > 0 ? Math.floor((root.to - root.from) / root.stepSize) + 1 : 0
			TrackDot {
				required property int modelData
				index: modelData
			}
		}
	}

	handle: StyledRect {
		width: root.pressed ? 2 : 4
		height: root.height
		x: root.handleGap + (root.visualPosition * (root.availableWidth - root.handleGap * 2)) - width / 2
		anchors.verticalCenter: parent.verticalCenter
		radius: Appearance.rounding.normal
		color: Colors.colors.primary

		Behavior on width {
			NumbAnim {
				duration: Appearance.animations.durations.small
			}
		}
	}
}
