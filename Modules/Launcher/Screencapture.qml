pragma ComponentBehavior: Bound

import Quickshell.Wayland
import Quickshell.Io
import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: screencapture

	property int currentIndex: 0
	property bool isScreencaptureOpen: false
	property string scriptPath: `${Quickshell.shellDir}/Assets/screen-capture.sh`

	LazyLoader {
		activeAsync: screencapture.isScreencaptureOpen

		component: PanelWindow {
			id: captureWindow

			visible: screencapture.isScreencaptureOpen
			focusable: true
			anchors {
				right: true
				left: true
			}

			WlrLayershell.namespace: "shell:capture"

			exclusiveZone: 0
			implicitWidth: 400
			implicitHeight: 350
			margins.left: 450
			margins.right: 450
			color: "transparent"

			Item {
				anchors.fill: parent

				StyledRect {
					anchors.fill: parent
					radius: Appearance.rounding.large
					color: Colors.colors.background
					border.color: Colors.colors.outline
					border.width: 2

					property int padding: Appearance.spacing.large

					ColumnLayout {
						anchors.fill: parent
						anchors.margins: parent.padding
						spacing: Appearance.spacing.small

						Repeater {
							model: [
								{
									name: "Screenshot window apps",
									icon: "select_window_2",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", `${Quickshell.shellDir}/Assets/screen-capture.sh --screenshot-window`]
										});
									}
								},
								{
									name: "Screenshot selection",
									icon: "select",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", `${Quickshell.shellDir}/Assets/screen-capture.sh --screenshot-selection`]
										});
									}
								},
								{
									name: "Screenshot eDP-1",
									icon: "monitor",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", `${Quickshell.shellDir}/Assets/screen-capture.sh --screenshot-eDP-1`]
										});
									}
								},
								{
									name: "Screenshot HDMI-A-2",
									icon: "monitor",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", `${Quickshell.shellDir}/Assets/screen-capture.sh --screenshot-HDMI-A-2`]
										});
									}
								},
								{
									name: "Screenshot both screen",
									icon: "dual_screen",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", `${Quickshell.shellDir}/Assets/screen-capture.sh --screenshot-both-screens`]
										});
									}
								},
							]

							delegate: StyledRect {
								id: iconDelegate

								required property var modelData
								required property int index

								Layout.preferredHeight: 45

								RowLayout {
									id: rowIndex

									anchors.fill: parent
									Layout.alignment: Qt.AlignCenter
									spacing: Appearance.spacing.normal

									focus: iconDelegate.index === screencapture.currentIndex
									Keys.onEnterPressed: {
										iconDelegate.modelData.action();
										screencapture.isScreencaptureOpen = false;
									}
									Keys.onReturnPressed: {
										iconDelegate.modelData.action();
										screencapture.isScreencaptureOpen = false;
									}
									Keys.onUpPressed: screencapture.currentIndex > 0 ? screencapture.currentIndex-- : ""
									Keys.onDownPressed: screencapture.currentIndex < 4 ? screencapture.currentIndex++ : ""
									Keys.onEscapePressed: screencapture.isScreencaptureOpen = !screencapture.isScreencaptureOpen

									transform: Scale {
										id: scaleTransform

										origin.x: rowIndex.width / 2
										origin.y: rowIndex.height / 2
										xScale: iconDelegate.index === screencapture.currentIndex ? 1.05 : 1.0
										yScale: iconDelegate.index === screencapture.currentIndex ? 1.05 : 1.0

										Behavior on xScale {
											NumbAnim {
												easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
											}
										}
										Behavior on yScale {
											NumbAnim {
												easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
											}
										}
									}

									MatIcon {
										id: icon

										icon: iconDelegate.modelData.icon
										color: iconDelegate.index === screencapture.currentIndex ? Colors.colors.primary : Colors.colors.outline
										font.pixelSize: Appearance.fonts.large * 1.1
										Layout.margins: Appearance.spacing.small
										Layout.alignment: Qt.AlignVCenter

										Behavior on color {
											ColAnim {
												easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
											}
										}
									}

									StyledText {
										id: name

										color: iconDelegate.index === screencapture.currentIndex ? Colors.colors.primary : Colors.colors.outline
										font.pixelSize: Appearance.fonts.large * 1.1
										Layout.margins: Appearance.spacing.small
										text: iconDelegate.modelData.name
									}

									MouseArea {
										id: mArea

										cursorShape: Qt.PointingHandCursor
										hoverEnabled: true
										onClicked: {
											icon.focus = true;
											iconDelegate.modelData.action();
										}
										onEntered: parent.focus = true
									}
								}
							}
						}
					}
				}
			}
		}
	}

	IpcHandler {
		target: "screencapture"

		function toggle(): void {
			screencapture.isScreencaptureOpen = !screencapture.isScreencaptureOpen;
		}
	}
}
