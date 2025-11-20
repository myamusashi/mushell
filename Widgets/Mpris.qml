pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import qs.Configs
import qs.Helpers
import qs.Services as Player
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
                return hours + ":" + minutes.toString().padStart(2, '0') + ":" + secs.toString().padStart(2, '0');

            return minutes + ":" + secs.toString().padStart(2, '0');
        }

        RowLayout {
            id: mediaInfo

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                icon: Player.Mpris.active === null ? "question_mark" : Player.Mpris.active.playbackState === MprisPlaybackState.Playing ? "genres" : "play_circle"
                font.pointSize: Appearance.fonts.large
                color: Themes.m3Colors.m3OnBackground
            }

            StyledText {
                text: Player.Mpris.active === null ? "null" : Player.Mpris.active.trackArtist
                color: Themes.m3Colors.m3OnBackground
            }
        }

        MArea {
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
