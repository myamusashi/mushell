pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Components.Base
import qs.Services
import Vast.ImageCache
import Vast.Lyrics

StyledRect {
	id: mediaPlayerRect

	property alias mediaLayout: mediaLayout

    visible: Players.active !== null
    color: GlobalStates.drawerColors
    radius: Appearance.rounding.normal

    property url url: ""
    property string cachedArtPath: ""
    property var trackArtColors: {
        const FALLBACK = {
            primary: "#D0BCFF",
            onPrimary: "#381E72",
            primaryContainer: "#4F378B",
            onPrimaryContainer: "#EADDFF",
            secondary: "#CCC2DC",
            onSecondary: "#332D41",
            tertiary: "#EFB8C8",
            onTertiary: "#492532",
            surface: "#141218",
            surfaceVariant: "#49454F",
            onSurface: "#E6E1E5",
            onSurfaceVariant: "#CAC4D0",
            outline: "#938F99"
        };

        if (colorTrackArt.colors.length === 0)
            return FALLBACK;

        function toHex(c) {
            const ch = v => Math.round(v * 255).toString(16).padStart(2, '0');
            return `#${ch(c.r)}${ch(c.g)}${ch(c.b)}`;
        }

        function luminance(c) {
            const lin = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
            return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
        }

        function contrastRatio(l1, l2) {
            const [lighter, darker] = l1 > l2 ? [l1, l2] : [l2, l1];
            return (lighter + 0.05) / (darker + 0.05);
        }

        function hslSaturation(c) {
            const max = Math.max(c.r, c.g, c.b);
            const min = Math.min(c.r, c.g, c.b);
            const lightness = (max + min) / 2;
            return (max === min) ? 0 : (max - min) / (1 - Math.abs(2 * lightness - 1));
        }

        function chroma(c) {
            return hslSaturation(c) * luminance(c);
        }

        function onColor(bgLuminance, lightEntry, darkEntry) {
            const contrastWithLight = contrastRatio(bgLuminance, lightEntry.lum);
            const contrastWithDark = contrastRatio(bgLuminance, darkEntry.lum);
            return toHex(contrastWithLight >= contrastWithDark ? lightEntry.color : darkEntry.color);
        }

        const tones = Array.from(colorTrackArt.colors).map(c => ({
                    color: c,
                    lum: luminance(c)
                })).sort((a, b) => a.lum - b.lum);

        const n = tones.length;
        const black = tones[0];
        const white = tones[n - 1];

        function atTone(t) {
            return tones[Math.max(0, Math.min(n - 1, Math.round(t * (n - 1))))];
        }

        const surfaceTone = atTone(0.06);
        const surfaceVariantTone = atTone(0.17);
        const outlineTone = atTone(0.60);

        function mostVivid(fromRatio, toRatio) {
            return tones.slice(Math.floor(fromRatio * n), Math.ceil(toRatio * n)).reduce((best, cur) => chroma(cur.color) > chroma(best.color) ? cur : best);
        }

        const primaryTone = mostVivid(0.70, 1.00);
        const primaryContainerTone = mostVivid(0.20, 0.45);

        const secondaryTone = atTone(0.75);
        const tertiaryTone = atTone(0.88);

        return {
            surface: toHex(surfaceTone.color),
            surfaceVariant: toHex(surfaceVariantTone.color),
            onSurface: toHex(white.color),
            onSurfaceVariant: toHex(outlineTone.color),
            outline: toHex(outlineTone.color),
            primary: toHex(primaryTone.color),
            onPrimary: onColor(primaryTone.lum, white, black),
            primaryContainer: toHex(primaryContainerTone.color),
            onPrimaryContainer: onColor(primaryContainerTone.lum, white, black),
            secondary: toHex(secondaryTone.color),
            onSecondary: onColor(secondaryTone.lum, white, black),
            tertiary: toHex(tertiaryTone.color),
            onTertiary: onColor(tertiaryTone.lum, white, black)
        };
    }

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
            command = ["curl", "-sLz", targetPath, "-o", targetPath, url];
            running = true;
        }

        onExited: function (exitCode) { // qmllint disable
            if (exitCode === 0)
                mediaPlayerRect.cachedArtPath = targetPath;
        }
    }

    ColorQuantizer {
        id: colorTrackArt
        source: Qt.resolvedUrl(mediaPlayerRect.cachedArtPath !== "" ? mediaPlayerRect.cachedArtPath : `file://${Paths.projectRoot}/Assets/images/kuru.gif`)
        depth: 3
        rescaleSize: 64
    }

    Connections {
        target: Players

        function onIndexChanged() {
            const url = Players.active?.trackArtUrl ?? "";
            url.startsWith("http") ? artDownloader.download(url) : mediaPlayerRect.cachedArtPath = url;
        }
    }

    Connections {
        target: Players.active

        function onTrackChanged() {
            const url = Players.active?.trackArtUrl ?? "";
            if (url.startsWith("http"))
                artDownloader.download(url);
            else
                mediaPlayerRect.cachedArtPath = url;

            const localPath = url.replace("file://", "");
            if (localPath && !url.startsWith("http"))
                ImageCache.copyAndPreload(localPath, Qt.size(300, 300));
        }
    }

    Component.onCompleted: {
        const url = Players.active?.trackArtUrl ?? "";
        url.startsWith("http") ? artDownloader.download(url) : mediaPlayerRect.cachedArtPath = url;
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
                    color: dynOnSurface
                    font.pixelSize: Appearance.fonts.size.large
                }

                Image {
                    anchors.fill: parent
                    visible: Players.active?.trackArtUrl !== "" && Players.active?.trackArtUrl !== undefined
                    source: Players.active?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    text: Players.active?.trackTitle ?? ""
                    color: dynOnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Players.active?.trackArtist ?? ""
                    color: dynOnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.xSmall
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Icon {
                icon: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                color: dynOnSurface
                font.pixelSize: Appearance.fonts.size.large

                MArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Players.active?.togglePlaying()
                }
            }

            Icon {
                icon: "skip_next"
                color: dynOnSurface
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
            source: Players.active?.trackArtUrl ?? ""
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
                        source: Players.active?.trackArtUrl ?? ""
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
                            text: modelData.text
                            font.pixelSize: Appearance.fonts.size.normal
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideNone
                            color: isActiveLine ? mediaPlayerRect.dynPrimary : mediaPlayerRect.dynOnSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignCenter
                spacing: Appearance.spacing.small

                StyledButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    bgRadius: Appearance.rounding.normal
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

                StyledButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    bgRadius: Appearance.rounding.normal
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
