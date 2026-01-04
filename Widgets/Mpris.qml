pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell.Services.Mpris

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: root

    color: "transparent"
    implicitHeight: parent.height
    implicitWidth: mediaInfo.width

    readonly property int index: 0

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

        Icon {
            type: Icon.Material
            icon: Players.active === null ? "question_mark" : Players.active.playbackState === MprisPlaybackState.Playing ? "genres" : "play_circle"
            font.pointSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnBackground
        }

        StyledText {
            text: Players.active === null ? "null" : Players.active.trackArtist
            color: Colours.m3Colors.m3OnBackground
        }
    }

    MArea {
        anchors.fill: mediaInfo
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: GlobalStates.isMediaPlayerOpen = !GlobalStates.isMediaPlayerOpen
    }
}
