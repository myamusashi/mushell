pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import qs.Data
import qs.Helpers
import qs.Components

Rectangle {
	id: root

	property int index
	readonly property MprisPlayer player: Mpris.players.values[index]

	Layout.fillWidth: true
	Layout.fillHeight: true
	color: Appearance.colors.withAlpha(Appearance.colors.surface, 0.7)
	radius: Appearance.rounding.normal
	border.color: Appearance.colors.outline
	border.width: 2
	clip: true

	Rectangle {
		id: wallCover

		anchors.fill: parent
		color: "transparent"
		z: -1

		Image {
			id: coverSource

			anchors.fill: parent

			visible: false
			source: root.player.trackArtUrl
			fillMode: Image.PreserveAspectCrop
		}

		MultiEffect {
			blurEnabled: true
			blurMax: 30
			blur: 1.0

			source: coverSource
			anchors.fill: parent
			maskEnabled: true
			maskSource: maskWallCover
		}

		Item {
			id: maskWallCover

			anchors.fill: parent
			layer.enabled: true
			visible: false
			Rectangle {
				width: wallCover.width
				height: wallCover.height
				radius: root.radius
			}
		}

		// Make title readable
		Rectangle {
			anchors.fill: parent

			color: root.player.trackArtUrl.length > 0 ? Appearance.colors.withAlpha(Appearance.colors.shadow, 0.1) : "transparent"
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

			Rectangle {
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
							source: root.player.trackArtUrl.length > 0 ? root.player.trackArtUrl : notFoundImage
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
							Rectangle {
								anchors.fill: parent
								radius: width / 2
							}
						}
					}

					Column {
						anchors.horizontalCenter: parent.horizontalCenter
						spacing: 8

						StyledText {
							id: titleText

							anchors.horizontalCenter: parent.horizontalCenter
							text: root.player.trackTitle.length > 0 ? root.player.trackTitle : "null"
							color: Appearance.colors.on_background
							font.pixelSize: Appearance.fonts.medium * 1.5
							font.bold: true
							horizontalAlignment: Text.AlignHCenter
							wrapMode: Text.WordWrap
							width: Math.min(implicitWidth, 300)
						}

						StyledText {
							id: artistText

							anchors.horizontalCenter: parent.horizontalCenter
							text: root.player.trackArtist.length > 0 ? root.player.trackArtist : "null"
							color: Appearance.colors.on_background
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
										if (!root.player.canGoPrevious) {
											console.log("Can't go back");
											return;
										}
										root.player.previous();
									}
								},
								{
									icon: root.player.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle",
									action: () => {
										root.player.togglePlaying();
									}
								},
								{
									icon: "skip_next",
									action: () => {
										root.player.next();
									}
								}
							]

							delegate: Item {
								id: delegateController

								required property var modelData
								width: 44
								height: 44

								Rectangle {
									id: bgCon

									anchors.fill: parent
									anchors.margins: 4
									color: Appearance.colors.primary
									radius: Appearance.rounding.small
									opacity: clickArea.containsMouse ? 1 : 0.7
									scale: clickArea.pressed ? 0.95 : 1.0

									Behavior on opacity {
										NumberAnimation {
											duration: 150
										}
									}

									Behavior on scale {
										NumberAnimation {
											duration: 100
										}
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
									color: Appearance.colors.on_primary
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
							text: root.player.position > 0 ? root.formatTime(root.player.position) : "00:00"
							color: Appearance.colors.on_background

							Timer {
								running: root.player.playbackState == MprisPlaybackState.Playing
								interval: 100
								repeat: true
								onTriggered: root.player.positionChanged()
							}
						}

						StyledSlide {
							value: root.player.length > 0 ? root.player.position / root.player.length : 0

							FrameAnimation {
								running: root.player.playbackState == MprisPlaybackState.Playing
								onTriggered: root.player.positionChanged()
							}

							onMoved: root.player.position = value * root.player.length
						}
					}
				}
			}
		}
	}
}
