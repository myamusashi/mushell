pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Mpris

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: root

	property bool isMediaPlayerOpen: false

	function formatTime(seconds) {
		const hours = Math.floor(seconds / 3600);
		const minutes = Math.floor((seconds % 3600) / 60);
		const secs = Math.floor(seconds % 60);

		if (hours > 0)
			return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

		return `${minutes}:${secs.toString().padStart(2, '0')}`;
	}

	property string url: ""

	function getTrackUrl(): void {
		trackUrl.running = true;
	}

	Process {
		id: trackUrl

		command: ["sh", "-c", "playerctl metadata | grep xesam:url | awk '{print $3}'"]
		running: true
		stdout: StdioCollector {
			onStreamFinished: {
				const res = text.trim();
				root.url = res;
			}
		}
	}

	LazyLoader {
		active: root.isMediaPlayerOpen

		component: PanelWindow {
			anchors {
				top: true
			}
			property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			property real monitorWidth: monitor.width / monitor.scale
			property real monitorHeight: monitor.height / monitor.scale
			implicitWidth: monitorWidth * 0.25
			implicitHeight: container.implicitHeight
			exclusiveZone: 0

			margins.right: (monitorWidth - implicitWidth) / 2

			color: "transparent"

			StyledRect {
				id: container

				implicitWidth: parent.width
				implicitHeight: contentLayout.implicitHeight + 15
				color: Themes.colors.surface_container
				radius: Appearance.rounding.normal

				RowLayout {
					id: contentLayout

					anchors.fill: parent
					anchors.margins: 10
					spacing: Appearance.spacing.normal

					Rectangle {
						Layout.preferredWidth: 120
						Layout.preferredHeight: 120
						color: "transparent"

						Loader {
							active: root.isMediaPlayerOpen
							anchors.centerIn: parent
							width: 120
							height: 120

							sourceComponent: Item {
								anchors.fill: parent
								Image {
									id: coverArt

									anchors.fill: parent
									source: Player.active && Player.active.trackArtUrl !== "" ? Player.active.trackArtUrl :
																								"root:/Assets/kuru.gif"

									fillMode: Image.PreserveAspectCrop
									visible: Player.active !== null
									opacity: 0.5
									cache: false
									asynchronous: true

									layer.enabled: true
									layer.effect: MultiEffect {
										maskEnabled: true
										maskSource: mask
									}
								}

								StyledText {
									anchors.centerIn: parent
									width: 120
									text: "Achievement Unlocked: 🏆 Static Image Starer - You expected the kuru spin but trackArtUrl decided to disconnect. GG."
									wrapMode: Text.Wrap
									elide: Text.ElideRight
									color: Themes.colors.on_surface
									visible: Player.active && Player.active.trackArtUrl === ""
								}

								AnimatedImage {
									id: coverNullArt

									anchors.fill: parent
									visible: Player.active === null
									asynchronous: true
									cache: false
									source: Player.active === null ? "root:/Assets/kuru.gif" : ""
								}

								Item {
									id: mask

									anchors.fill: parent
									layer.enabled: true
									visible: false

									Rectangle {
										anchors.fill: parent
										color: "white"
										radius: Appearance.rounding.small
									}
								}
							}
						}
					}

					ColumnLayout {
						id: controlLayout

						Layout.fillWidth: true

						Column {
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignLeft
							spacing: 2

							StyledLabel {
								width: parent.width
								text: Player.active ? Player.active.trackTitle : ""
								color: Themes.colors.on_background
								font.pixelSize: Appearance.fonts.large
								wrapMode: Text.NoWrap
								elide: Text.ElideRight
							}

							RowLayout {
								Layout.preferredWidth: 50

								StyledText {
									Layout.preferredWidth: width
									text: Player.active ? Player.active.trackArtist : ""
									color: Themes.colors.on_background
									font.pixelSize: Appearance.fonts.small
									wrapMode: Text.NoWrap
									elide: Text.ElideRight
								}

								StyledText {
									text: Player.active ? "•" : ""
									color: Themes.colors.on_background
									font.pixelSize: Appearance.fonts.extraLarge
								}

								StyledText {
									text: Player.active ? "Watched on " : ""
									color: Themes.colors.on_background
									font.pixelSize: Appearance.fonts.small
								}

								IconImage {
									source: Quickshell.iconPath(Player.active.desktopEntry)
									asynchronous: true
									implicitWidth: 20
									implicitHeight: 20

									MouseArea {
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: Qt.openUrlExternally(root.url)
									}
								}
							}
						}

						Item {
							Layout.fillHeight: true
							Layout.minimumHeight: 5
						}

						RowLayout {
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
							spacing: 10

							StyledText {
								id: timeTrack

								text: Player.active == null ? "00:00" : `${root.formatTime(Player.active?.position)} 
${root.formatTime(Player.active?.length)}`
								font.pixelSize: Appearance.fonts.large
								color: Themes.colors.on_background

								Timer {
									running: Player.active !== null && Player.active.playbackState
											 == MprisPlaybackState.Playing
									interval: 1000
									repeat: true
									onTriggered: Player.active.positionChanged()
								}
							}

							Item {
								Layout.fillWidth: true
							}

							MatIcon {
								id: pauseButton

								icon: Player.active === null ? "pause_circle" : Player.active.playbackState
															   === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
								color: {
									if (pauseMouseArea.pressed)
									return Themes.withAlpha(Themes.colors.primary, 0.08);
									else if (pauseMouseArea.containsMouse)
									return Themes.withAlpha(Themes.colors.primary, 0.12);
									else
									return Themes.colors.primary;
								}
								font.pixelSize: Appearance.fonts.extraLarge * 1.5

								MouseArea {
									id: pauseMouseArea

									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: Player.active ? Player.active.togglePlaying() : ""
								}
							}
						}

						RowLayout {
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
							spacing: Appearance.spacing.normal

							StyledButton {
								iconButton: "skip_previous"
								iconSize: 10
								onClicked: Player.active ? Player.active.previous() : {}
							}

							StyledSlide {
								id: barSlide

								value: Player.active === null ? 0 : Player.active.length > 0 ? Player.active.position
																							   / Player.active.length : 0

								Layout.fillWidth: true
								Layout.preferredHeight: 40
								valueWidth: 0
								valueHeight: 0

								FrameAnimation {
									running: Player.active && Player.active.playbackState == MprisPlaybackState.Playing
									onTriggered: Player.active.positionChanged()
								}

								onMoved: Player.active ? Player.active.position = value * Player.active.length : {}
							}

							StyledButton {
								iconButton: "skip_next"
								iconSize: 10
								onClicked: Player.active ? Player.active.next() : {}
							}
						}
					}
				}
			}
		}
	}
}
