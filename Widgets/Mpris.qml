pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import qs.Data
import qs.Helpers
import qs.Components
import qs.Modules.MediaPlayer

Loader {
	active: true
	asynchronous: true

	Layout.alignment: Qt.AlignCenter

	sourceComponent: StyledRect {
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
				return hours + ":" + minutes.toString().padStart(2, '0') + ":" + secs.toString().padStart(2,
																										  '0');


			return minutes + ":" + secs.toString().padStart(2, '0');
		}

		RowLayout {
			id: mediaInfo

			anchors.centerIn: parent
			spacing: Appearance.spacing.small

			MatIcon {
				icon: Player.active === null ? "question_mark" : Player.active.playbackState
											   === MprisPlaybackState.Playing ? "genres" : "play_circle"
				font.pixelSize: Appearance.fonts.medium * 1.8
				color: Themes.colors.on_background
			}

			StyledText {
				text: Player.active === null ? "null" : Player.active.trackArtist
				color: Themes.colors.on_background
			}
		}

		MouseArea {
			anchors.fill: mediaInfo

			cursorShape: Qt.PointingHandCursor
			hoverEnabled: true

			onClicked: root.playerControlShow = !root.playerControlShow
		}

		MediaPlayer {
			isMediaPlayerOpen: root.playerControlShow
		}
	}
}
