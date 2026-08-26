pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services

StyledRect {
    readonly property int index: 0

    color: "transparent"
    implicitHeight: parent.height
    implicitWidth: mediaInfo.width

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = Math.floor(seconds % 60);

        if (hours > 0)
            return hours + ":" + minutes.toString().padStart(2, '0') + ":" + secs.toString().padStart(2, '0');

        return minutes + ":" + secs.toString().padStart(2, '0');
    }

    IpcHandler {
        target: "mpris"

        function togglePlaying(): void {
            Players.active?.togglePlaying();
        }
        function next(): void {
            Players.active?.next();
        }
        function previous(): void {
            Players.active?.previous();
        }
        function stop(): void {
            Players.active?.stop();
        }
        function status(): bool {
            return Players.active?.isPlaying;
        }
        function list(): string {
            const playerSummaries = [];
            const players = Players.players;
            for (let i = 0; i < players.length; i++) {
                const player = players[i];
                playerSummaries.push({
                    identity: player.identity,
                    trackTitle: player.trackTitle,
                    trackArtist: player.trackArtist,
                    playbackStatus: player.playbackStatus,
                    volume: player.volume,
                    status: player.isPlaying
                });
            }
            return JSON.stringify(playerSummaries);
        }
    }

    RowLayout {
        id: mediaInfo

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        RowLayout {
            Repeater {
                model: [
                    {
                        icon: "skip_previous",
                        clicked: () => Players.active?.previous()
                    },
                    {
                        icon: Players.active === null ? "question_mark" : Players.active.playbackState === MprisPlaybackState.Playing ? "genres" : "play_circle",
                        clicked: () => Players.active?.togglePlaying()
                    },
                    {
                        icon: "skip_next",
                        clicked: () => Players.active?.next()
                    }
                ]
                delegate: FloatingButton {
                    required property var modelData

                    implicitWidth: 24
                    implicitHeight: 24
                    backgroundRadius: Appearance.rounding.normal
                    icon.name: modelData.icon
                    icon.color: Colours.m3Colors.m3Background
                    icon.size: Appearance.fonts.size.large * 1.4
                    onClicked: modelData.clicked()
                }
            }
        }

        StyledText {
            text: Players.active === null ? "null" : Players.active.trackArtist
            color: Colours.m3Colors.m3OnBackground
            font.weight: Font.DemiBold
        }
    }
}
