pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.Data
import qs.Components

Scope {
	id: scope

	property bool isWallpaperSwitcherOpen: false
	property string currentWallpaper: Paths.currentWallpaper
	property var wallpaperList: []
	property string searchQuery: ""
	property var filteredWallpaperList: {
		if (searchQuery === "")
			return wallpaperList;

		return wallpaperList.filter(path => {
			const fileName = path.split('/').pop().toLowerCase();
			return fileName.includes(searchQuery.toLowerCase());
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

		component: PanelWindow {
			id: root

			anchors {
				right: true
				top: true
				bottom: true
			}

			focusable: true

			property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			property real monitorWidth: monitor.width / monitor.scale
			property real monitorHeight: monitor.height / monitor.scale

			implicitWidth: monitorWidth * 0.15
			margins.top: monitorHeight * 0.1
			margins.bottom: monitorHeight * 0.1
			exclusiveZone: 1
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
						text: scope.searchQuery
						font.pixelSize: Appearance.fonts.medium
						focus: true

						onTextChanged: {
							scope.searchQuery = text;
							if (pathView.count > 0) {
								pathView.currentIndex = 0;
							}
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
						pathItemCount: Math.min(5, scope.filteredWallpaperList.length)

						Component.onCompleted: {
							const currentIndex = scope.wallpaperList.indexOf(Paths.currentWallpaper);
							if (currentIndex !== -1) {
								pathView.currentIndex = currentIndex;
							}
						}
						delegate: Item {
							id: delegateItem

							width: pathView.width * 1
							height: pathView.height * 0.2

							required property var modelData
							required property int index
							property bool isCurrentItem: PathView.isCurrentItem

							scale: isCurrentItem ? 1.0 : 0.5
							opacity: isCurrentItem ? 1.0 : 0.5

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
											anchors.fill: parent
											source: "file://" + delegateItem.modelData
											sourceSize.width: width
											sourceSize.height: height
											fillMode: Image.PreserveAspectCrop
											asynchronous: true
											smooth: false
											antialiasing: false
											cache: false
										}

										MouseArea {
											id: mArea

											anchors.fill: parent
											onClicked: {
												pathView.currentIndex = delegateItem.index;
												Quickshell.execDetached({
													command: ["sh", "-c", `qs -c lock ipc call img set ${delegateItem.modelData}`]
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
							startX: pathView.width / 2
							startY: 0

							PathAttribute {
								name: "z"
								value: 0
							}
							PathAttribute {
								name: "scale"
								value: 0.7
							}

							PathLine {
								x: pathView.width / 2
								y: pathView.height / 2
							}

							PathAttribute {
								name: "z"
								value: 10
							}
							PathAttribute {
								name: "scale"
								value: 1.0
							}

							PathLine {
								x: pathView.width / 2
								y: pathView.height
							}

							PathAttribute {
								name: "z"
								value: 0
							}
							PathAttribute {
								name: "scale"
								value: 0.7
							}
						}

						preferredHighlightBegin: 0.5
						preferredHighlightEnd: 0.5

						Keys.onPressed: event => {
							if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
								Quickshell.execDetached({
									command: ["sh", "-c", `qs -c lock ipc call img set ${model[currentIndex]}`]
								});
							}

							if (event.key === Qt.Key_Escape)
								scope.isWallpaperSwitcherOpen = false;

							if (event.key === Qt.Key_Up)
								decrementCurrentIndex();

							if (event.key === Qt.Key_Down)
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
}
