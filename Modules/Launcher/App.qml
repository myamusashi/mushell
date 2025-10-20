pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Components
import qs.Helpers

Scope {
	id: root

	property int currentIndex: 0
	property bool isLauncherOpen: false

	// Thx caelestia
	function launch(entry: DesktopEntry): void {
		if (entry.runInTerminal)
			Quickshell.execDetached({
				command: ["app2unit", "--", "foot", `${Quickshell.shellDir}/Assets/wrap_term_launch.sh`, ...entry.command],
				workingDirectory: entry.workingDirectory
			});
		else
			Quickshell.execDetached({
				command: ["app2unit", "--", ...entry.command],
				workingDirectory: entry.workingDirectory
			});
	}

	LazyLoader {
		id: appLoader

		active: root.isLauncherOpen

		component: PanelWindow {
			id: launcher

			property ShellScreen modelData

			anchors {
				left: true
				right: true
			}

			WlrLayershell.namespace: "shell:app"

			property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			property int monitorWidth: monitor.width / monitor.scale
			property int monitorHeight: monitor.height / monitor.scale

			visible: root.isLauncherOpen
			focusable: true

			color: "transparent"
			screen: modelData
			exclusiveZone: 0
			implicitWidth: monitorWidth * 0.3
			implicitHeight: monitorHeight * 0.5
			margins.left: monitorWidth * 0.3
			margins.right: margins.left

			StyledRect {
				id: rectLauncher

				anchors.fill: parent

				radius: Appearance.rounding.large
				color: Colors.colors.background
				border.color: Colors.colors.outline
				border.width: 2

				ColumnLayout {
					anchors.fill: parent

					anchors.margins: Appearance.padding.normal
					spacing: Appearance.spacing.normal

					TextField {
						id: search

						Layout.fillWidth: true
						Layout.preferredHeight: 60
						placeholderText: "  Search"
						font.family: Appearance.fonts.family_Sans
						focus: true
						font.pixelSize: Appearance.fonts.large * 1.2
						color: Colors.colors.on_surface
						placeholderTextColor: Colors.colors.on_surface_variant

						background: StyledRect {
							radius: Appearance.rounding.small
							color: Colors.withAlpha(Colors.colors.surface, 0)
							// border.color: Colors.colors.on_background
							// border.width: 2
						}

						onTextChanged: {
							root.currentIndex = 0;
						}

						Keys.onPressed: function (event) {
							switch (event.key) {
							case Qt.Key_Return:
							case Qt.Key_Tab:
							case Qt.Key_Enter:
								listView.focus = true;
								event.accepted = true;
								break;
							case Qt.Key_Escape:
								root.isLauncherOpen = false;
								event.accepted = true;
								break;
							case Qt.Key_Down:
								listView.focus = true;
								event.accepted = true;
								break;
							}
						}
					}

					ListView {
						id: listView

						Layout.fillWidth: true
						Layout.fillHeight: true
						Layout.preferredHeight: 400

						model: ScriptModel {
							values: Fuzzy.fuzzySearch(DesktopEntries.applications.values, search.text, "name")
						}

						keyNavigationWraps: false
						currentIndex: root.currentIndex
						maximumFlickVelocity: 3000
						orientation: Qt.Vertical
						clip: true

						boundsBehavior: Flickable.DragAndOvershootBounds
						flickDeceleration: 1500

						Behavior on currentIndex {
							NumbAnim {}
						}

						onModelChanged: {
							if (root.currentIndex >= model.values.length)
								root.currentIndex = Math.max(0, model.values.length - 1);
						}

						delegate: MouseArea {
							id: entryMouseArea

							required property DesktopEntry modelData
							required property int index

							property bool keyboardActive: listView.activeFocus
							property real itemScale: 1.0

							width: listView.width
							height: 60
							hoverEnabled: !keyboardActive

							Behavior on itemScale {
								NumbAnim {}
							}

							onEntered: {
								root.currentIndex = index;
							}

							onClicked: {
								root.isLauncherOpen = false;
								root.launch(modelData);
							}

							Keys.onPressed: kevent => {
								switch (kevent.key) {
								case Qt.Key_Escape:
									root.isLauncherOpen = false;
									break;
								case Qt.Key_Enter:
								case Qt.Key_Return:
									root.launch(modelData);
									root.isLauncherOpen = false;
									break;
								case Qt.Key_Up:
									if (index === 0) {
										search.focus = true;
									}
									break;
								}
							}

							StyledRect {
								anchors.fill: parent

								anchors.margins: 2

								transform: Scale {
									xScale: entryMouseArea.itemScale
									yScale: entryMouseArea.itemScale
									origin.x: width / 2
									origin.y: height / 2
								}

								readonly property bool selected: entryMouseArea.containsMouse || (listView.currentIndex === entryMouseArea.index && listView.activeFocus)
								color: selected ? Colors.withAlpha(Colors.colors.on_surface, 0.1) : "transparent"
								radius: Appearance.rounding.normal

								Behavior on color {
									ColorAnimation {
										duration: Appearance.animations.durations.small
										easing.bezierCurve: Appearance.animations.curves.standard
									}
								}

								RowLayout {
									anchors.fill: parent

									anchors.margins: Appearance.padding.small
									spacing: Appearance.spacing.normal

									Loader {
										active: root.isLauncherOpen
										asynchronous: true

										Layout.preferredWidth: 40
										Layout.preferredHeight: 40

										sourceComponent: IconImage {
											Layout.alignment: Qt.AlignVCenter
											Layout.preferredWidth: 40
											Layout.preferredHeight: 40
											asynchronous: true

											source: Quickshell.iconPath(entryMouseArea.modelData.icon) || ""

											opacity: 0
											Component.onCompleted: {
												opacity = 1;
											}
											Behavior on opacity {
												NumbAnim {}
											}
										}
									}

									StyledText {
										Layout.fillWidth: true
										Layout.alignment: Qt.AlignVCenter
										text: entryMouseArea.modelData.name || ""
										font.pixelSize: Appearance.fonts.normal
										color: Colors.colors.on_background
										elide: Text.ElideRight

										opacity: 0
										Component.onCompleted: {
											opacity = 1;
										}
										Behavior on opacity {
											NumbAnim {}
										}
									}
								}
							}
						}

						highlightFollowsCurrentItem: true
						highlightResizeDuration: Appearance.animations.durations.small
						highlightMoveDuration: Appearance.animations.durations.small
						highlight: StyledRect {
							color: Colors.colors.primary
							radius: Appearance.rounding.normal
							opacity: 0.06

							scale: 0.95
							Behavior on scale {
								NumbAnim {}
							}

							Component.onCompleted: {
								scale = 1.0;
							}
						}
					}
				}
			}
		}
	}

	IpcHandler {
		target: "launcher"

		function toggle(): void {
			root.isLauncherOpen = !root.isLauncherOpen;
		}
	}
}
