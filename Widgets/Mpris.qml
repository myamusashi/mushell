pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import qs.Data
import qs.Helpers
import qs.Components

Loader { 
	active: root.isBarOpen
	asynchronous: true

	anchors.centerIn: parent
	
	sourceComponent: Rectangle {
	id: root

	anchors.centerIn: parent

	color: "transparent"

	readonly property int index: 0
	property bool playerControlShow: false

	function formatTime(seconds) {
		const hours = Math.floor(seconds / 3600);
		const minutes = Math.floor((seconds % 3600) / 60);
		const secs = Math.floor(seconds % 60);

		if (hours > 0)
			return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

		return `${minutes}:${secs.toString().padStart(2, '0')}`;
	}

	RowLayout {
		id: mediaInfo

		anchors.centerIn: parent
		spacing: Appearance.spacing.small

		MatIcon {
			icon: Player.active === null ? "question_mark" : Player.active.playbackState === MprisPlaybackState.Playing ? "genres" : "play_circle"
			font.pixelSize: Appearance.fonts.medium * 1.8
			color: Appearance.colors.on_background
		}

		ColumnLayout {
			StyledText {
				text: Player.active === null ? "null" : Player.active.trackArtist
				color: Appearance.colors.on_background
			}

			StyledSlide {
				id: barSlider

				value: Player.active.length > 0 ? Player.active.position / Player.active.length : 0

				valueWidth: parent.width
				valueHeight: 5

				Timer {
					running: Player.active.playbackState == MprisPlaybackState.Playing
					repeat: true
					onTriggered: Player.active.positionChanged()
				}

				handleHeight: 0
				handleWidth: 0
				Layout.preferredWidth: parent.width
				Layout.preferredHeight: 5
			}
		}
	}

	MouseArea {
		anchors.fill: mediaInfo

		cursorShape: Qt.PointingHandCursor
		hoverEnabled: true
		onClicked: root.playerControlShow = !root.playerControlShow
	}

	RowLayout {
		id: mediaControl

		anchors.left: parent.left
		anchors.leftMargin: Appearance.margin.large * 4
		anchors.verticalCenter: parent.verticalCenter

		opacity: root.playerControlShow ? 1 : 0
		visible: opacity > 0

		Behavior on opacity {
			NumbAnim {
				duration: 800
				easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
			}
		}

		Repeater {
			model: [
				{
					icon: Player.active === null ? "question_mark" : "skip_previous",
					action: () => {
						if (!Player.active.canGoPrevious) {
							console.log("Can't go back");
							return;
						}
						Player.active.previous();
					}
				},
				{
					icon: Player.active === null ? "question_mark" : Player.active.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle",
					action: () => {
						Player.active.togglePlaying();
					}
				},
				{
					icon: Player.active === null ? "question_mark" : "skip_next",
					action: () => {
						Player.active.next();
					}
				}
			]

			delegate: Item {
				id: delegateItem

				required property var modelData

				Layout.preferredHeight: 28
				Layout.preferredWidth: 28

				opacity: root.playerControlShow ? 1 : 0
				scale: root.playerControlShow ? 1 : 0.8

				Behavior on opacity {
					NumbAnim {
						duration: 200 + (root.index * 50)
					}
				}

				Behavior on scale {
					NumbAnim {
						duration: 200 + (root.index * 50)
					}
				}

				Rectangle {
					anchors.fill: parent
					anchors.margins: 2
					color: Appearance.colors.on_primary
					radius: Appearance.rounding.small
					opacity: clickArea.containsMouse ? 1 : 0.8
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
					onClicked: delegateItem.modelData.action()
				}

				MatIcon {
					anchors.centerIn: parent
					color: Appearance.colors.primary
					font.pixelSize: Appearance.fonts.large * 1.2
					icon: delegateItem.modelData.icon
				}
			}
		}
	}
}
}
