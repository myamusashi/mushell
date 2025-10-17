pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

LazyLoader {
	id: loader

	required property bool controlCenterShow
	property PwNode node: Pipewire.defaultAudioSink

	active: controlCenterShow

	component: PopupWindow {
		anchor.window: root.isBarOpen

		mask: Region {}

		PwObjectTracker {
			objects: [loader.node]
		}
		visible: true

		StyledRect {
			anchors.fill: parent
			color: Colors.colors.background

			StyledText {
				text: "test"
				color: Colors.colors.on_background
			}
		}
	}
}

// StyledPopup {
// 	RowLayout {
// 		anchors.fill: parent
//
// 		StyledText {
// 			text: "test"
// 			color: Colors.colors.on_background
// 		}
// 	}
// }

// PopupWindow {
// 	id: root
//
// 	required property var modelData
// 	property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
// 	property string icon: Audio.getIcon(root.node)
// 	property PwNode node: Pipewire.defaultAudioSink
// 	property var screenX: monitor.x
// 	property var screenY: monitor.y
// 	property var scaleMonitor: (monitor.scale === null || monitor.scale === undefined) ? 1.0 : monitor.scale
// 	property var screenWidth: monitor.width / scaleMonitor
// 	property var screenHeight: monitor.height / scaleMonitor
//
// 	property var baseWidth: screenWidth * 0.35
// 	property var baseHeight: screenHeight * 0.25
//
// 	anchor.window: modelData
// 	anchor.rect.x: (screenWidth * 0.65) - (baseWidth / 2)
// 	anchor.rect.y: screenY + ((modelData.height + 20) / scaleMonitor)
//
// 	mask: Region {}
//
// 	PwObjectTracker {
// 		objects: [root.node]
// 	}
//
// 	width: baseWidth
// 	height: baseHeight
//
// 	visible: true
// 	color: "transparent"
//
// 	RowLayout {
// 		anchors.fill: parent
// 		anchors.leftMargin: 20
// 		spacing: Appearance.spacing.normal
//
// 		StyledRect {
// 			anchors.fill: parent
// 			color: Colors.colors.background
// 			border.color: Colors.colors.outline
// 			border.width: 2
// 			radius: Appearance.spacing.normal
//
// 			MouseArea {
// 				anchors.fill: parent
//
// 				hoverEnabled: true
// 				cursorShape: Qt.PointingHandCursor
//
// 				StyledSlide {
// 					value: (root.node.audio.volume * 100).toFixed(0)
// 					valueWidth: 250
// 					valueHeight: 5
// 					onMoved: root.node.audio.volume = value * root.node.audio.volume
// 					handleHeight: 10
// 					handleWidth: 10
// 				}
// 			}
// 		}
// 	}
// }
