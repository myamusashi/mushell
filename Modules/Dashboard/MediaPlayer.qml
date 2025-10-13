pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	active: dashboardLoader.activeAsync
	asynchronous: true

	anchors.fill: parent

	sourceComponent: StyledRect {
		id: root

		Layout.fillWidth: true
		Layout.fillHeight: true
		color: Player.active == null ? Colors.withAlpha(Colors.colors.background, 0.8) : Colors.withAlpha(Colors.colors.background, 0.5)
		radius: Appearance.rounding.normal
		border.color: Colors.colors.outline
		border.width: 2
		clip: true

		StyledRect {
			id: wallCover

			anchors.fill: parent
			color: "transparent"
			z: -1

			Loader {

				active: Player.active == null
				asynchronous: true

				anchors.fill: parent
				sourceComponent: AnimatedImage {
					id: coverNull

					anchors.fill: parent

					visible: Player.active == null
					source: Qt.resolvedUrl("root:/Assets/kuru.gif")
				}
			}

			Loader {
				id: coverImageLoader
				active: Player.active !== null
				asynchronous: true
				anchors.fill: parent
				sourceComponent: Image {
					id: coverSource

					anchors.fill: parent

					visible: false
					source: Player.active.trackArtUrl
					fillMode: Image.PreserveAspectCrop

					layer.enabled: true
					layer.effect: MultiEffect {
						autoPaddingEnabled: false

						blurEnabled: true
						blurMax: 40
						blur: 0.7

						source: coverSource
						anchors.fill: parent
						maskEnabled: true
						maskSource: maskWallCover
					}
				}
			}

			// MultiEffect {
			// 	autoPaddingEnabled: false
			//
			// 	blurEnabled: true
			// 	blurMax: 40
			// 	blur: 0.7
			//
			// 	source:
			// 	anchors.fill: parent
			// 	maskEnabled: true
			// 	maskSource: maskWallCover
			// }

			Item {
				id: maskWallCover

				anchors.fill: parent
				layer.enabled: true
				visible: false
				StyledRect {
					width: wallCover.width
					height: wallCover.height
					radius: root.radius
				}
			}
		}

		function formatTime(seconds) {
			const hours = Math.floor(seconds / 3600);
			const minutes = Math.floor((seconds % 3600) / 60);
			const secs = Math.floor(seconds % 60);

			if (hours > 0)
				return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

			return `${minutes}:${secs.toString().padStart(2, '0')}`;
		}

		ColumnLayout {
			anchors.fill: parent

			Item {
				id: mprisControll

				Layout.fillWidth: true
				Layout.fillHeight: true

				StyledRect {
					anchors.fill: parent
					color: "transparent"

					Column {
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.top: parent.top
						anchors.topMargin: 60
						spacing: Appearance.spacing.large

						Item {
							id: coverContainer

							anchors.horizontalCenter: parent.horizontalCenter
							width: 100
							height: 100

							Image {
								id: cover

								anchors.centerIn: parent

								property string notFoundImage: Qt.resolvedUrl(Quickshell.shellDir + "/Assets/image_not_found.svg")

								visible: false
								source: Player.active == null ? notFoundImage : Qt.resolvedUrl(Player.active.trackArtUrl)
								fillMode: Image.PreserveAspectCrop
							}

							MultiEffect {
								source: cover
								anchors.fill: parent
								maskEnabled: true
								maskSource: maskCover
							}

							Item {
								id: maskCover

								anchors.fill: parent
								layer.enabled: true
								visible: false
								StyledRect {
									anchors.fill: parent
									radius: width / 2
								}
							}
						}

						Column {
							anchors.horizontalCenter: parent.horizontalCenter
							spacing: Appearance.spacing.small

							StyledText {
								id: titleText

								anchors.horizontalCenter: parent.horizontalCenter
								text: Player.active == null ? "null" : Player.active.trackTitle
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.medium * 1.5
								font.bold: true
								horizontalAlignment: Text.AlignHCenter
								wrapMode: Text.WordWrap
								width: Math.min(implicitWidth, 300)
							}

							StyledText {
								id: artistText

								anchors.horizontalCenter: parent.horizontalCenter
								text: Player.active == null ? "null" : Player.active.trackArtist
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.medium * 1.1
								opacity: 0.8
								horizontalAlignment: Text.AlignHCenter
								wrapMode: Text.WordWrap
								width: Math.min(implicitWidth, 300)
							}
						}

						Row {
							anchors.horizontalCenter: parent.horizontalCenter
							spacing: Appearance.spacing.large

							Repeater {
								model: [
									{
										icon: "skip_previous",
										action: () => {
											if (!Player.active.canGoPrevious) {
												console.log("Can't go back");
												return;
											}
											Player.active.previous();
										}
									},
									{
										icon: Player.active.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle",
										action: () => {
											Player.active.togglePlaying();
										}
									},
									{
										icon: "skip_next",
										action: () => {
											Player.active.next();
										}
									}
								]

								delegate: Item {
									id: delegateController

									required property var modelData
									width: 44
									height: 44

									StyledRect {
										id: bgCon

										anchors.fill: parent
										anchors.margins: 4
										color: Colors.colors.primary
										radius: Appearance.rounding.small
										opacity: clickArea.containsMouse ? 1 : 0.7
										scale: clickArea.pressed ? 0.95 : 1.0

										Behavior on opacity {
											NumbAnim {}
										}

										Behavior on scale {
											NumbAnim {}
										}
									}

									MouseArea {
										id: clickArea

										anchors.fill: parent
										cursorShape: Qt.PointingHandCursor
										hoverEnabled: true
										onClicked: delegateController.modelData.action()
									}

									MatIcon {
										anchors.centerIn: parent
										color: Colors.colors.on_primary
										font.pixelSize: Appearance.fonts.large * 1.5
										icon: delegateController.modelData.icon
									}
								}
							}
						}

						Column {
							anchors.horizontalCenter: parent.horizontalCenter
							spacing: 8

							StyledText {
								id: timeTrack

								anchors.horizontalCenter: parent.horizontalCenter
								text: Player.active == null ? "00:00" : root.formatTime(Player.active.position)
								color: Colors.colors.on_background

								Timer {
									running: Player.active.playbackState == MprisPlaybackState.Playing
									interval: 100
									repeat: true
									onTriggered: Player.active.positionChanged()
								}
							}

							StyledSlide {
								id: barSlide

								value: Player.active.length > 0 ? Player.active.position / Player.active.length : 0

								valueWidth: 300
								valueHeight: 10

								FrameAnimation {
									running: Player.active.playbackState == MprisPlaybackState.Playing
									onTriggered: {
										Player.active.positionChanged();
									}
								}

								onMoved: Player.active.position = value * Player.active.length
							}
						}
					}
				}
			}
		}
	}
}
