pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Vast.Lyrics

import qs.Core.Configs
import qs.Core.Utils
import qs.Core.States
import qs.Services
import qs.Components.Base
import qs.Components.Button
import qs.Widgets

RowLayout {
    id: root

    property var trackArtColors: ({})
    property var formatTime: function (seconds) {
        return "0:00";
    }

    function cleanDesktopEntry(entry: string): string {
        if (!entry || entry === "No Player")
            return entry;
        const parts = entry.split(".");
        const name = parts[parts.length - 1];
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    spacing: Appearance.spacing.small

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Appearance.margin.normal

        Loader {
            anchors.fill: parent
            active: true
            asynchronous: false
            sourceComponent: playerControls
            enabled: !Configs.mediaPlayer.showLyrics
            opacity: Configs.mediaPlayer.showLyrics ? 0 : 1
            scale: Configs.mediaPlayer.showLyrics ? 0.96 : 1

            Behavior on opacity {
                NAnim {}
            }
            Behavior on scale {
                NAnim {}
            }
        }

        Loader {
            anchors.fill: parent
            active: true
            asynchronous: false
            sourceComponent: lyricsControls
            enabled: Configs.mediaPlayer.showLyrics
            opacity: Configs.mediaPlayer.showLyrics ? 1 : 0
            scale: Configs.mediaPlayer.showLyrics ? 1 : 0.96

            Behavior on opacity {
                NAnim {}
            }
            Behavior on scale {
                NAnim {}
            }
        }
    }

    Component {
        id: lyricsControls

        RowLayout {
            spacing: Appearance.spacing.large

            ColumnLayout {
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: Appearance.margin.small
                implicitWidth: parent.width * 0.5
                implicitHeight: parent.height

                ClippingRectangle {
                    Layout.alignment: Qt.AlignCenter
                    implicitHeight: 60
                    implicitWidth: 60
                    radius: Appearance.rounding.full

                    Image {
                        id: trackArt

                        source: Players.active.trackArtUrl
                        sourceSize: Qt.size(60, 60)
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true

                        Behavior on opacity {
                            NAnim {}
                        }
                    }
                }

                Wavy {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    activeColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                    value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0
                    onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                    FrameAnimation {
                        running: GlobalStates.isMediaPlayerOpen && Players.active?.playbackState == MprisPlaybackState.Playing
                        onTriggered: Players.active.positionChanged()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.large

                    StyledText {
                        text: Players.active?.trackArtist ?? ""
                        color: Configs.mediaPlayer.dynamicColorsCover ? Qt.alpha(root.trackArtColors.onSurface, 0.8) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.8)
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: Players.active == null ? "0:00" : `${root.formatTime(Players.active?.position)} / ${root.formatTime(Players.active?.length)}` // qmllint disable
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold

                        Timer {
                            running: GlobalStates.isQuickSettingsOpen && Players.active?.playbackState == MprisPlaybackState.Playing
                            interval: 1000
                            repeat: true
                            onTriggered: Players.active.positionChanged()
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    spacing: Appearance.spacing.normal

                    Icon {
                        icon: "discover_tune"
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.large
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Configs.mediaPlayer.showLyrics = false
                        }
                    }

                    Icon {
                        icon: Players.active?.shuffleSupported || Players.active?.shuffleSupported || Players.active?.shuffle ? "shuffle_on" : "shuffle"
                        color: Players.active?.shuffleSupported || Players.active?.shuffle ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        font.pixelSize: Appearance.fonts.size.large
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        enabled: Players.active?.shuffleSupported

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Players.active)
                                    Players.active.shuffle = !Players.active.shuffle;
                            }
                        }
                    }

                    Icon {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        icon: "skip_previous"
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.previous()
                        }
                    }

                    Icon {
                        icon: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        MArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.togglePlaying()
                        }
                    }

                    Icon {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        icon: "skip_next"
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.next()
                        }
                    }

                    FloatingButton {
                        implicitWidth: 18
                        implicitHeight: 18
                        bgRadius: Appearance.rounding.normal
                        icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                        icon.color: Players.active?.loopSupported || (Players.active?.loopState === MprisLoopState.Playlist || Players.active?.loopState === MprisLoopState.Track) ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        color: "transparent"
                        enabled: Players.active?.loopSupported
                        onClicked: {
                            if (!Players.active)
                                return;
                            switch (Players.active.loopState) {
                            case MprisLoopState.None:
                                Players.active.loopState = MprisLoopState.Playlist;
                                break;
                            case MprisLoopState.Playlist:
                                Players.active.loopState = MprisLoopState.Track;
                                break;
                            case MprisLoopState.Track:
                                Players.active.loopState = MprisLoopState.None;
                                break;
                            }
                        }
                    }
                }
            }

            Component.onCompleted: {
                if (LyricsProvider.currentLineIndex < 0)
                    lyricsView.listView.positionViewAtBeginning();
                else
                    lyricsView.listView.positionViewAtIndex(LyricsProvider.currentLineIndex, ListView.Center);
            }

            Connections {
                target: Players.active

                function onTrackChanged() {
                    if (LyricsProvider.currentLineIndex < 0) {
                        LyricsProvider.fetch(Players.active.trackTitle, Players.active.trackArtist, Players.active.length);
                        lyricsView.listView.positionViewAtBeginning();
                    } else
                        lyricsView.listView.positionViewAtIndex(LyricsProvider.currentLineIndex, ListView.Center);
                }

                function onPostTrackChanged() {
                    if (LyricsProvider.currentLineIndex < 0)
                        lyricsView.listView.positionViewAtBeginning();
                    else
                        lyricsView.listView.positionViewAtIndex(LyricsProvider.currentLineIndex, ListView.Center);
                }

                function onPositionChanged() {
                    LyricsProvider.setPlayback(Players.active.position, Players.active.rate, Players.active.isPlaying);
                }
            }

            LyricsView {
                id: lyricsView

                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: Appearance.margin.small
                implicitWidth: parent.width * 0.4
                implicitHeight: parent.height
                activeColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                inactiveColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.tertiary : Colours.m3Colors.m3Tertiary
            }
        }
    }

    Component {
        id: playerControls

        ColumnLayout {
            Layout.margins: 8
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Behavior on opacity {
                NAnim {}
            }

            StyledText {
                Layout.fillWidth: true
                text: Players.active?.trackTitle ?? ""
                color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    text: Players.active?.trackArtist ?? ""
                    color: Configs.mediaPlayer.dynamicColorsCover ? Qt.alpha(root.trackArtColors.onSurface, 0.8) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.8)
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Players.active == null ? "0:00" : `${root.formatTime(Players.active?.position)} / ${root.formatTime(Players.active?.length)}` // qmllint disable
                    color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold

                    Timer {
                        running: GlobalStates.isQuickSettingsOpen && Players.active?.playbackState == MprisPlaybackState.Playing
                        interval: 1000
                        repeat: true
                        onTriggered: Players.active.positionChanged()
                    }
                }
            }

            Wavy {
                Layout.fillWidth: true
                implicitWidth: 28
                activeColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0
                enableWave: Players.active?.playbackState === MprisPlaybackState.Playing && !pressed
                onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                FrameAnimation {
                    running: GlobalStates.isMediaPlayerOpen && Players.active?.playbackState == MprisPlaybackState.Playing
                    onTriggered: Players.active.positionChanged()
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: controlsRow.implicitHeight

                RowLayout {
                    id: controlsRow

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    Icon {
                        icon: "lyrics"
                        color: enabled ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurfaceVariant : Colours.m3Colors.m3OnSurfaceVariant)
                        font.pixelSize: Appearance.fonts.size.larger
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        enabled: LyricsProvider.state === LyricsProvider.State.Ready

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (LyricsProvider.state === LyricsProvider.State.Ready)
                                    Configs.mediaPlayer.showLyrics = true;
                            }
                        }
                    }

                    Icon {
                        icon: Players.active?.shuffleSupported || Players.active?.shuffleSupported || Players.active?.shuffle ? "shuffle_on" : "shuffle"
                        color: Players.active?.shuffleSupported || Players.active?.shuffle ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        font.pixelSize: Appearance.fonts.size.larger
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        enabled: Players.active?.shuffleSupported

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Players.active)
                                    Players.active.shuffle = !Players.active.shuffle;
                            }
                        }
                    }

                    Icon {
                        icon: "skip_previous"
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.previous()
                        }
                    }

                    Icon {
                        icon: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.extraLarge * 1.2
                        MArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.togglePlaying()
                        }
                    }

                    Icon {
                        icon: "skip_next"
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.next()
                        }
                    }

                    FloatingButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        bgRadius: Appearance.rounding.normal
                        icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                        icon.color: Players.active?.loopSupported || (Players.active?.loopState === MprisLoopState.Playlist || Players.active?.loopState === MprisLoopState.Track) ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        color: "transparent"
                        enabled: Players.active?.loopSupported
                        onClicked: {
                            if (!Players.active)
                                return;
                            switch (Players.active.loopState) {
                            case MprisLoopState.None:
                                Players.active.loopState = MprisLoopState.Playlist;
                                break;
                            case MprisLoopState.Playlist:
                                Players.active.loopState = MprisLoopState.Track;
                                break;
                            case MprisLoopState.Track:
                                Players.active.loopState = MprisLoopState.None;
                                break;
                            }
                        }
                    }
                }

                ComboBox {
                    id: playerComboBox

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    model: Players.players
                    textRole: "desktopMenu"
                    onActivated: index => {
                        currentIndex = index;
                        Players.index = index;
                        const player = Players.players[index];
                        LyricsProvider.fetch(player.trackTitle, player.trackArtist, player.length);
                    }

                    contentItem: Row {
                        spacing: Appearance.spacing.small
                        leftPadding: Appearance.padding.normal

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Players.active?.desktopEntry === "" ? Quickshell.iconPath("helium", "image-missing") : IconUtils.iconForId(Players.active.desktopEntry)
                            implicitWidth: 20
                            implicitHeight: 20
                            asynchronous: true
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 100
                            text: Players.active?.desktopEntry === "" ? "Helium" : root.cleanDesktopEntry(Players.active?.desktopEntry) ?? "No Player"
                            color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.large
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    background: StyledRect {
                        implicitWidth: 140
                        implicitHeight: 28
                        color: "transparent"
                    }

                    popup: Popup {
                        y: playerComboBox.height + 4
                        x: playerComboBox.width - width
                        width: 220
                        padding: 0
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                        enter: Transition {
                            NAnim {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: Appearance.animations.durations.small
                            }
                            NAnim {
                                property: "scale"
                                from: 0.95
                                to: 1
                                duration: Appearance.animations.durations.small
                            }
                        }
                        exit: Transition {
                            NAnim {
                                property: "opacity"
                                from: 1
                                to: 0
                                duration: Appearance.animations.durations.small
                            }
                        }

                        background: StyledRect {
                            color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.surfaceVariant : Colours.m3Colors.m3SurfaceVariant
                            radius: Appearance.rounding.large

                            Elevation {
                                anchors.fill: parent
                                z: -1
                                level: 2
                                radius: parent.radius - 2
                            }
                        }

                        contentItem: ListView {
                            id: listView

                            implicitHeight: Math.min(contentHeight, 320)
                            model: playerComboBox.delegateModel
                            cacheBuffer: 0
                            clip: true
                            currentIndex: playerComboBox.currentIndex

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            header: Item {
                                height: 8
                            }
                            footer: Item {
                                height: 8
                            }
                        }
                    }

                    delegate: ItemDelegate {
                        id: itemDel

                        required property MprisPlayer modelData
                        required property int index

                        width: playerComboBox.popup.width
                        highlighted: playerComboBox.highlightedIndex === index

                        onClicked: {
                            playerComboBox.currentIndex = index;
                            Players.index = index;
                            playerComboBox.popup.close();
                        }

                        background: StyledRect {
                            id: itemBg
                            property color target: (playerComboBox.currentIndex === itemDel.index || itemDel.highlighted) ? Qt.alpha(Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary, 0.18) : "transparent"
                            property color cFrom
                            property color cTo
                            property bool cActive: false
                            property real cBlend: 1.0
                            onCBlendChanged: {
                                if (!cActive)
                                    return;
                                if (cBlend >= 1) {
                                    color = cTo;
                                    cActive = false;
                                } else if (cBlend > 0) {
                                    color = Colours.blendColors(cFrom, cTo, cBlend);
                                }
                            }
                            onTargetChanged: {
                                cAnim.stop();
                                cFrom = color;
                                cTo = target;
                                cActive = true;
                                cBlend = 0.0;
                                cAnim.start();
                            }

                            anchors {
                                left: parent.left
                                right: parent.right
                                margins: Appearance.margin.small
                            }
                            radius: Appearance.rounding.normal
                            height: parent.height

                            NAnim {
                                id: cAnim
                                target: itemBg
                                property: "cBlend"
                                from: 0.0
                                to: 1.0
                                duration: Appearance.animations.durations.small
                            }

                            SimpleRipple {
                                anchors.fill: parent
                                xClipRadius: itemBg.radius
                                yClipRadius: itemBg.radius
                                color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                            }
                        }

                        contentItem: Row {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Appearance.margin.large
                                rightMargin: Appearance.margin.large
                            }
                            spacing: Appearance.spacing.normal

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                source: IconUtils.iconForId(itemDel.modelData.desktopEntry)
                                asynchronous: true
                                implicitWidth: 20
                                implicitHeight: 20
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.cleanDesktopEntry(itemDel.modelData.desktopEntry) ?? ""
                                color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: playerComboBox.currentIndex === itemDel.index ? Font.Medium : Font.Normal
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
