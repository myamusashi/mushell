pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Data
import qs.Components

Scope {
	id: scope

	property bool isWallpaperSwitcherOpen: false
	property string currentWallpaper: Paths.currentWallpaper
	property var wallpaperList: []
	property string searchQuery: ""
	property string debouncedSearchQuery: ""

	Timer {
		id: searchDebounceTimer

		interval: 300
		repeat: false
		onTriggered: scope.debouncedSearchQuery = scope.searchQuery
	}

	property var filteredWallpaperList: {
		if (debouncedSearchQuery === "")
			return wallpaperList;

		const query = debouncedSearchQuery.toLowerCase();
		return wallpaperList.filter(path => {
			const fileName = path.split('/').pop().toLowerCase();
			return fileName.includes(query);
		});
	}

	Process {
		id: listWallpaper

		workingDirectory: Paths.wallpaperDir
		command: ["sh", "-c", `find -L ${Paths.wallpaperDir} -type d -path */.* -prune -o -not -name .* -type f -print`]
		running: true
		stdout: StdioCollector {
			onStreamFinished: {
				const wallList = text.trim().split('\n').filter(path => path.length > 0);
				scope.wallpaperList = wallList;
			}
		}
	}

	LazyLoader {
		id: loader

		active: scope.isWallpaperSwitcherOpen
		onActiveChanged: {
			if (!active) {
				scope.searchQuery = "";
				scope.debouncedSearchQuery = "";

				cleanupTimer.start();
			}
		}

		component: PanelWindow {
			id: root

			anchors {
				bottom: true
			}

			focusable: true

			property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			property real monitorWidth: monitor.width / monitor.scale
			property real monitorHeight: monitor.height / monitor.scale

			implicitWidth: monitorWidth * 0.8
			implicitHeight: monitorHeight * 0.35
			margins.bottom: monitorHeight * 0.05
			exclusiveZone: 0
			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
			color: "transparent"

			StyledRect {
				anchors.fill: parent
				color: Colors.colors.surface
				radius: Appearance.rounding.large

				ColumnLayout {
					anchors.fill: parent
					anchors.margins: Appearance.spacing.normal
					spacing: Appearance.spacing.normal

					TextField {
						id: searchField

						Layout.fillWidth: true
						Layout.preferredHeight: 40
						placeholderText: "Search wallpapers..."
						placeholderTextColor: Colors.colors.surface_variant
						text: scope.searchQuery
						font.pixelSize: Appearance.fonts.medium
						color: Colors.colors.on_surface
						focus: true

						onTextChanged: {
							scope.searchQuery = text;
							searchDebounceTimer.restart();

							if (pathView.count > 0)
								pathView.currentIndex = 0;
						}

						background: StyledRect {
							color: Colors.withAlpha(Colors.colors.surface_container_high, 0.12)
							radius: Appearance.rounding.normal
							border.color: searchField.activeFocus ? Colors.colors.primary : Colors.colors.outline_variant
							border.width: searchField.activeFocus ? 2 : 1
						}

						Keys.onDownPressed: pathView.focus = true
						Keys.onEscapePressed: scope.isWallpaperSwitcherOpen = false
					}

					PathView {
						id: pathView

						Layout.fillWidth: true
						Layout.fillHeight: true

						model: scope.filteredWallpaperList
						clip: true

						pathItemCount: Math.min(7, scope.filteredWallpaperList.length)
						cacheItemCount: 7

						Component.onCompleted: {
							const currentIndex = scope.wallpaperList.indexOf(Paths.currentWallpaper);
							if (currentIndex !== -1)
								pathView.currentIndex = currentIndex;
						}

						delegate: Item {
							id: delegateItem

							width: pathView.height * 0.7
							height: pathView.height * 0.85

							required property var modelData
							required property int index
							property bool isCurrentItem: PathView.isCurrentItem

							// Linear scaling based on position
							scale: isCurrentItem ? 1.0 : 0.75
							opacity: isCurrentItem ? 1.0 : 0.6

							Behavior on scale {
								NumbAnim {
									duration: Appearance.animations.durations.small
								}
							}

							Behavior on opacity {
								NumbAnim {
									duration: Appearance.animations.durations.small
								}
							}

							Behavior on y {
								NumbAnim {
									duration: Appearance.animations.durations.small
								}
							}

							StyledRect {
								anchors.fill: parent
								color: "transparent"
								radius: Appearance.rounding.normal
								border.color: delegateItem.isCurrentItem ? searchField.focus ? Colors.withAlpha(Colors.colors.primary, 0.4) : Colors.colors.primary : mArea.containsPress ? Colors.colors.secondary : Colors.colors.outline_variant
								border.width: delegateItem.isCurrentItem ? 3 : 1

								ColumnLayout {
									anchors.fill: parent
									anchors.margins: 4
									spacing: Appearance.spacing.small

									Item {
										Layout.fillWidth: true
										Layout.fillHeight: true

										Image {
											id: previewImage

											anchors.fill: parent
											source: "file://" + delegateItem.modelData

											sourceSize.width: 150
											sourceSize.height: 150

											fillMode: Image.PreserveAspectCrop
											asynchronous: true
											smooth: true
											cache: true
											mipmap: true
										}

										MouseArea {
											id: mArea

											anchors.fill: parent
											onClicked: {
												pathView.currentIndex = delegateItem.index;
												Quickshell.execDetached({
													command: ["sh", "-c", `shell ipc call img set ${delegateItem.modelData}`]
												});
											}
										}
									}

									StyledLabel {
										Layout.fillWidth: true
										Layout.preferredHeight: 20
										Layout.margins: 4
										text: delegateItem.modelData.split('/').pop()
										color: "white"
										elide: Text.ElideMiddle
										font.pixelSize: Appearance.fonts.small
										style: Text.Outline
										styleColor: "black"
										horizontalAlignment: Text.AlignHCenter
									}
								}
							}
						}

						path: Path {
							startX: 0
							startY: pathView.height / 2

							PathAttribute {
								name: "z"
								value: 0
							}

							PathLine {
								x: pathView.width / 2
								y: pathView.height / 2
							}

							PathAttribute {
								name: "z"
								value: 10
							}

							PathLine {
								x: pathView.width
								y: pathView.height / 2
							}

							PathAttribute {
								name: "z"
								value: 0
							}
						}

						preferredHighlightBegin: 0.5
						preferredHighlightEnd: 0.5

						Keys.onPressed: event => {
							if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
								Quickshell.execDetached({
									command: ["sh", "-c", `shell ipc call img set ${model[currentIndex]}`]
								});
							}

							if (event.key === Qt.Key_Escape)
								scope.isWallpaperSwitcherOpen = false;

							if (event.key === Qt.Key_Left)
								decrementCurrentIndex();

							if (event.key === Qt.Key_Right)
								incrementCurrentIndex();

							if (event.key === Qt.Key_Tab)
								searchField.focus = true;
						}
					}

					StyledLabel {
						Layout.alignment: Qt.AlignHCenter
						Layout.bottomMargin: Appearance.spacing.small
						text: pathView.count > 0 ? (pathView.currentIndex + 1) + " / " + pathView.count : "0 / 0"
						color: Colors.colors.on_surface
						font.pixelSize: Appearance.fonts.small
					}
				}
			}
		}
	}

	Timer {
		id: cleanupTimer

		interval: 500
		repeat: false
		onTriggered: {
			gc();
		}
	}
}
