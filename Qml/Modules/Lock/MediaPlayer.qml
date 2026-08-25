pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Components.Base
import qs.Components.Button
import qs.Services
import Vast.ImageCache
import Vast.Lyrics
import Vast.Utils

StyledRect {
    id: mediaPlayerRect

    property alias mediaLayout: mediaLayout

    visible: Players.active !== null
    color: GlobalStates.drawerColors
    radius: Appearance.rounding.normal

    property url url: ""
    property string cachedArtPath: ""
    readonly property var fallbackTrackArtColors: ({
            primary: Colours.m3Colors.m3Primary,
            onPrimary: Colours.m3Colors.m3OnPrimary,
            primaryContainer: Colours.m3Colors.m3PrimaryContainer,
            onPrimaryContainer: Colours.m3Colors.m3OnPrimaryContainer,
            secondary: Colours.m3Colors.m3Secondary,
            onSecondary: Colours.m3Colors.m3OnSecondary,
            tertiary: Colours.m3Colors.m3Tertiary,
            onTertiary: Colours.m3Colors.m3OnTertiary,
            surface: Colours.m3Colors.m3SurfaceContainerHighest,
            surfaceVariant: Colours.m3Colors.m3SurfaceVariant,
            onSurface: Colours.m3Colors.m3OnSurface,
            onSurfaceVariant: Colours.m3Colors.m3OnSurfaceVariant,
            outline: Colours.m3Colors.m3Outline
        })
    property var trackArtColors: fallbackTrackArtColors

    readonly property color dynPrimary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.primary : Colours.m3Colors.m3Primary
    readonly property color dynOnSurface: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
    readonly property color dynOnSurfaceVariant: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onSurfaceVariant : Colours.m3Colors.m3OnSurfaceVariant
    readonly property color dynOutline: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.outline : Colours.m3Colors.m3Outline
    readonly property color dynOnPrimary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onPrimary : Colours.m3Colors.m3OnPrimary
    readonly property color dynTertiary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.tertiary : Colours.m3Colors.m3Tertiary
    readonly property color dynSurface: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.surface : Colours.m3Colors.m3Surface
    readonly property color dynSurfaceVariant: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.surfaceVariant : Colours.m3Colors.m3SurfaceVariant

    Process {
        id: artDownloader
        property string targetPath: ""

        function download(url) {
            if (!url || url === "")
                return;
            const hash = Qt.md5(url);
            targetPath = `/tmp/qs_art_${hash}.jpg`;
            exec(["curl", "-sLz", targetPath, "-o", targetPath, url]);
        }

        onExited: function (exitCode, exitStatus) { // qmllint disable
            if (exitStatus !== 0)
                return;
            if (exitCode === 0 && targetPath === `/tmp/qs_art_${Qt.md5(Players.active?.trackArtUrl ?? "")}.jpg`)
                mediaPlayerRect.cachedArtPath = targetPath;
        }
    }

    ColorMaterial {
        id: trackArtMaterial

        source: mediaPlayerRect.cachedArtPath
        darkMode: Configs.colors.isDarkMode
        scheme: Colours.schemeEnum(Configs.colors.scheme)
        onColorsChanged: {
            if (ready)
                mediaPlayerRect.trackArtColors = colors;
        }
    }

    Connections {
        target: Players

        function onIndexChanged() {
            mediaPlayerRect.refreshTrackArt();
        }
    }

    onCachedArtPathChanged: {
        trackArtColors = fallbackTrackArtColors;
    }

    Connections {
        target: Players.active

        function onTrackChanged() {
            mediaPlayerRect.refreshTrackArt();
        }

        function onPostTrackChanged() {
            mediaPlayerRect.refreshTrackArt();
        }

        function onTrackArtUrlChanged() {
            mediaPlayerRect.refreshTrackArt();
        }
    }

    function refreshTrackArt() {
        const url = String(Players.active?.trackArtUrl ?? "");
        mediaPlayerRect.cachedArtPath = "";
        if (url.startsWith("http"))
            artDownloader.download(url);
        else
            mediaPlayerRect.cachedArtPath = url;

        const localPath = url.replace("file://", "");
        if (localPath && !url.startsWith("http"))
            ImageCache.copyAndPreload(localPath, Qt.size(300, 300));
    }

    Component.onCompleted: {
        mediaPlayerRect.refreshTrackArt();
    }

    Elevation {
        anchors.fill: parent
        level: 1
        radius: parent.radius
    }

    Layout.alignment: Qt.AlignVCenter
    implicitHeight: mediaLayout.implicitHeight + Appearance.margin.small * 2
    implicitWidth: Math.max(336, (mediaRow.implicitWidth + Appearance.margin.normal * 2) * 1.2)

    ColumnLayout {
        id: mediaLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.margin.small
        }
        spacing: Appearance.spacing.small

        RowLayout {
            id: mediaRow
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Item {
                implicitWidth: 28
                implicitHeight: 28

                Icon {
                    anchors.fill: parent
                    icon: "music_note"
                    color: mediaPlayerRect.dynOnSurface
                    font.pixelSize: Appearance.fonts.size.large
                }

                Image {
                    anchors.fill: parent
                    visible: Players.active?.trackArtUrl !== "" && Players.active?.trackArtUrl !== undefined
                    source: Players.active ? Players.active.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    text: Players.active?.trackTitle ?? ""
                    color: mediaPlayerRect.dynOnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Players.active?.trackArtist ?? ""
                    color: mediaPlayerRect.dynOnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Icon {
                icon: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                color: mediaPlayerRect.dynOnSurface
                font.pixelSize: Appearance.fonts.size.large

                MArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Players.active?.togglePlaying()
                }
            }

            Icon {
                icon: "skip_next"
                color: mediaPlayerRect.dynOnSurface
                font.pixelSize: Appearance.fonts.size.large

                MArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Players.active?.next()
                }
            }
        }

        Wavy {
            Layout.fillWidth: true
            implicitHeight: 28
            activeColor: mediaPlayerRect.dynPrimary
            inactiveColor: mediaPlayerRect.dynSurfaceVariant
            value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0
            enableWave: Players.active?.playbackState === MprisPlaybackState.Playing
            onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

            FrameAnimation {
                running: Players.active?.playbackState === MprisPlaybackState.Playing
                onTriggered: Players.active.positionChanged()
            }
        }
    }

    HoverHandler {
        id: mediaHover
        cursorShape: Qt.PointingHandCursor
    }

    ClippingRectangle {
        id: mediaPopup
        anchors.bottom: mediaPlayerRect.top
        anchors.bottomMargin: Appearance.spacing.small
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        color: mediaPlayerRect.dynSurface
        radius: Appearance.rounding.normal
        clip: true

        property bool popupHovered: false

        opacity: mediaHover.hovered || popupHovered ? 1 : 0
        scale: mediaHover.hovered || popupHovered ? 1 : 0.92
        visible: opacity > 0

        HoverHandler {
            onHoveredChanged: mediaPopup.popupHovered = hovered
        }

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.normal
            }
        }
        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
        }

        Elevation {
            anchors.fill: parent
            level: 3
            radius: parent.radius
        }

        implicitHeight: popupLayout.implicitHeight + Appearance.margin.normal * 2

        Image {
            id: popupCoverArt
            anchors.fill: parent
            source: Players.active ? Players.active.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: !!Players.active?.trackArtUrl
            layer.enabled: true
            layer.effect: FastBlur {
                source: popupCoverArt
                radius: Configs.generals.coverBlurRadius
            }
        }

        Rectangle {
            anchors.fill: parent
            color: mediaPlayerRect.dynSurface
            opacity: 0.82
        }

        ColumnLayout {
            id: popupLayout
            anchors {
                fill: parent
                margins: Appearance.margin.normal
            }
            spacing: Appearance.spacing.small

            RowLayout {
                spacing: Appearance.spacing.normal

                ClippingWrapperRectangle {
                    implicitWidth: 48
                    implicitHeight: 48
                    radius: Appearance.rounding.normal
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: Players.active ? Players.active.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Players.active?.trackTitle ?? ""
                        color: mediaPlayerRect.dynOnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: Players.active?.trackArtist ?? ""
                        color: mediaPlayerRect.dynOnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.small
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            Wavy {
                Layout.fillWidth: true
                implicitHeight: 24
                activeColor: mediaPlayerRect.dynPrimary
                inactiveColor: mediaPlayerRect.dynSurfaceVariant
                value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0
                enableWave: Players.active?.playbackState === MprisPlaybackState.Playing
                onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                FrameAnimation {
                    running: Players.active?.playbackState === MprisPlaybackState.Playing
                    onTriggered: Players.active.positionChanged()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                visible: Lyrics.lines.length > 0
                clip: true

                ListView {
                    id: lyricsListView
                    anchors.fill: parent
                    model: Lyrics.lines
                    spacing: 4
                    currentIndex: LyricsProvider.currentLineIndex
                    onCurrentIndexChanged: {
                        if (currentIndex < 0)
                            positionViewAtBeginning();
                        else
                            positionViewAtIndex(currentIndex, ListView.Center);
                    }

                    delegate: Item {
                        id: lyricDelegate

                        required property var modelData
                        required property int index

                        readonly property bool isActiveLine: index === LyricsProvider.currentLineIndex

                        width: lyricsListView.width
                        implicitHeight: lineText.implicitHeight
                        scale: isActiveLine ? 1.0 : 0.9
                        opacity: isActiveLine ? 1.0 : 0.5

                        Behavior on scale {
                            NAnim {
                                duration: 250
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }
                        Behavior on opacity {
                            NAnim {
                                duration: 250
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }

                        StyledText {
                            id: lineText
                            width: lyricsListView.width
                            text: lyricDelegate.modelData.text
                            font.pixelSize: Appearance.fonts.size.normal
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideNone
                            color: lyricDelegate.isActiveLine ? mediaPlayerRect.dynPrimary : mediaPlayerRect.dynOnSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignCenter
                spacing: Appearance.spacing.small

                FloatingButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    backgroundRadius: Appearance.rounding.normal
                    icon.name: Players.active?.shuffle ? "shuffle_on" : "shuffle"
                    icon.color: Players.active?.shuffle ? mediaPlayerRect.dynPrimary : mediaPlayerRect.dynOutline
                    color: "transparent"
                    enabled: Players.active?.shuffleSupported
                    onClicked: {
                        if (Players.active)
                            Players.active.shuffle = !Players.active.shuffle;
                    }
                }

                Icon {
                    icon: "skip_previous"
                    color: mediaPlayerRect.dynOnSurface
                    font.pixelSize: Appearance.fonts.size.extraLarge

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Players.active?.previous()
                    }
                }

                Icon {
                    icon: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                    color: mediaPlayerRect.dynOnSurface
                    font.pixelSize: Appearance.fonts.size.extraLarge

                    MArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Players.active?.togglePlaying()
                    }
                }

                Icon {
                    icon: "skip_next"
                    color: mediaPlayerRect.dynOnSurface
                    font.pixelSize: Appearance.fonts.size.extraLarge

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Players.active?.next()
                    }
                }

                FloatingButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    backgroundRadius: Appearance.rounding.normal
                    icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                    icon.color: Players.active?.loopState !== MprisLoopState.None ? mediaPlayerRect.dynPrimary : mediaPlayerRect.dynOutline
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

                function onPositionChanged() {
                    if (mediaHover.hovered || mediaPopup.popupHovered) {
                        const p = Players.active;
                        if (!p)
                            return;
                        LyricsProvider.setPlayback(p.position, p.rate, p.isPlaying);
                    }
                }
            }

            Component.onCompleted: {
                const p = Players.active;
                if (!p?.trackTitle)
                    return;
                LyricsProvider.fetch(p.trackTitle, p.trackArtist, p.length);
                LyricsProvider.setPlayback(p.position, p.rate, p.isPlaying);
            }
        }
    }
}
