pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Vast.Lyrics

import qs.Core.States
import qs.Services

Singleton {
    id: root

    readonly property var wordLines: LyricsProvider.wordLines
    readonly property var lines: LyricsProvider.lines
    readonly property bool synced: LyricsProvider.synced
    readonly property bool wordSynced: LyricsProvider.wordSynced
    readonly property int state: LyricsProvider.state
    readonly property int currentLineIndex: LyricsProvider.currentLineIndex
    readonly property int currentWordIndex: LyricsProvider.currentWordIndex
    readonly property real currentWordDuration: LyricsProvider.currentWordDuration
    property bool trackJustChanged: false
    property var offsets: ({})

    Connections {
        target: Players.active

        function onPostTrackChanged() {
            const p = Players.active;
            if (!p)
                return;
            LyricsProvider.clear();
            LyricsProvider.setPlayback(0, p.rate, p.isPlaying);
            LyricsProvider.fetch(p.trackTitle, p.trackArtist, p.length);
        }

        // re-anchor so dead-reckoning stays accurate
        function onPlaybackStateChanged() {
            const p = Players.active;
            if (!p)
                return;
            if (p.playbackState === MprisPlaybackState.Stopped) {
                LyricsProvider.clear();
                return;
            }
            LyricsProvider.setPlayback(p.position, p.rate, p.isPlaying);
        }
    }

    Connections {
        target: GlobalStates

        function onIsQuickSettingsOpenChanged() {
            if (!GlobalStates.isQuickSettingsOpen)
                return;
            const p = Players.active;
            if (!p?.trackTitle)
                return;
            LyricsProvider.setPlayback(p.position, p.rate, p.isPlaying);
        }
    }

    Component.onCompleted: {
        const p = Players.active;
        if (!p?.trackTitle)
            return;
        Qt.callLater(() => {
            LyricsProvider.fetch(p.trackTitle, p.trackArtist, p.length);
            LyricsProvider.setPlayback(p.position, p.rate, p.isPlaying);
        });
    }
}
