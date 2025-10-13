pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: session

	property int currentIndex: 0
	property bool isSessionOpen: false

	LazyLoader {
		activeAsync: session.isSessionOpen

		component: PanelWindow {
			id: sessionWindow
			visible: session.isSessionOpen
			focusable: true
			anchors.right: true
			margins.right: 10
			exclusiveZone: 0
			implicitWidth: 80
			implicitHeight: 550
			WlrLayershell.namespace: "shell:session"
			color: "transparent"

			Item {
				anchors.fill: parent

				StyledRect {
					anchors.fill: parent
					radius: Appearance.rounding.normal
					color: Colors.colors.background
					border.color: Colors.colors.outline
					border.width: 2

					ColumnLayout {
						anchors.fill: parent
						spacing: 5

						Repeater {
							model: [
								{
									icon: "power_settings_circle",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", "systemctl poweroff"]
										});
									}
								},
								{
									icon: "restart_alt",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", "systemctl reboot"]
										});
									}
								},
								{
									icon: "sleep",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", "systemctl suspend"]
										});
									}
								},
								{
									icon: "door_open",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", "hyprctl dispatch exit"]
										});
									}
								},
								{
									icon: "lock",
									action: () => {
										Quickshell.execDetached({
											command: ["sh", "-c", "qs -c lock ipc call lock lock"]
										});
									}
								}
							]

							delegate: StyledRect {
								id: rectDelegate

								required property var modelData
								required property int index
								property bool isHighlighted: mouseArea.containsMouse || (iconDelegate.focus && rectDelegate.index === session.currentIndex)

								Layout.alignment: Qt.AlignHCenter
								Layout.preferredWidth: 60
								Layout.preferredHeight: 70

								radius: Appearance.rounding.normal
								color: isHighlighted ? Colors.withAlpha(Colors.colors.secondary, 0.2) : "transparent"

								Behavior on color {
									ColAnim {}
								}

								MatIcon {
									id: iconDelegate

									color: Colors.colors.primary
									font.pixelSize: Appearance.fonts.large * 4
									icon: rectDelegate.modelData.icon

									focus: rectDelegate.index === session.currentIndex

									Keys.onEnterPressed: {
										rectDelegate.modelData.action();
										session.isSessionOpen = !session.isSessionOpen;
									}
									Keys.onReturnPressed: {
										rectDelegate.modelData.action();
										session.isSessionOpen = !session.isSessionOpen;
									}
									Keys.onUpPressed: session.currentIndex > 0 ? session.currentIndex-- : ""
									Keys.onDownPressed: session.currentIndex < 4 ? session.currentIndex++ : ""
									Keys.onEscapePressed: session.isSessionOpen = !session.isSessionOpen

									scale: mouseArea.pressed ? 0.95 : 1.0

									Behavior on scale {
										NumbAnim {}
									}

									MouseArea {
										id: mouseArea

										anchors.fill: parent
										cursorShape: Qt.PointingHandCursor
										hoverEnabled: true

										onClicked: {
											parent.focus = true;
											{
												rectDelegate.modelData.action();
												session.isSessionOpen = !session.isSessionOpen;
											}
											;
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
		target: "session"

		function toggle(): void {
			session.isSessionOpen = !session.isSessionOpen;
		}
	}
}
