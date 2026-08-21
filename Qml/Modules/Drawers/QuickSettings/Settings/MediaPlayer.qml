pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Core.States
import qs.Services
import qs.Components.Base
import Vast.ImageCache
import Vast.Utils

ClippingWrapperRectangle {
    id: root

    property url url: ""
    // thx claude
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
    property string cachedArtPath: ""

    Layout.alignment: Qt.AlignTop | Qt.AlignCenter
    Layout.fillWidth: true
    implicitHeight: 150
    color: Qt.alpha(Colours.m3Colors.m3Scrim, 0.5)
    radius: Appearance.rounding.normal
    visible: Players.active

    function formatTime(seconds) {
        const m = Math.floor((seconds % 3600) / 60);
        const s = Math.floor(seconds % 60);
        const h = Math.floor(seconds / 3600);
        return h > 0 ? `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}` : `${m}:${s.toString().padStart(2, '0')}`;
    }

    Component.onCompleted: {
        const url = Players.active?.trackArtUrl ?? "";
        url.startsWith("http") ? artDownloader.download(url) : root.cachedArtPath = url;
    }

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
                root.cachedArtPath = targetPath;
        }
    }

    Connections {
        target: Players

        function onIndexChanged() {
            root.refreshTrackArt();
        }
    }

    Connections {
        target: Players.active

        function onTrackChanged() {
            root.refreshTrackArt();
        }

        function onPostTrackChanged() {
            root.refreshTrackArt();
        }

        function onTrackArtUrlChanged() {
            root.refreshTrackArt();
        }
    }

    function refreshTrackArt() {
        const url = Players.active?.trackArtUrl ?? "";
        root.cachedArtPath = "";
        if (url.startsWith("http"))
            artDownloader.download(url);
        else
            root.cachedArtPath = url;

        const localPath = url.replace("file://", "");
        if (localPath && !url.startsWith("http"))
            ImageCache.copyAndPreload(localPath, Qt.size(300, 300));
    }

    ColorMaterial {
        id: trackArtMaterial

        source: root.cachedArtPath
        darkMode: Configs.colors.isDarkMode
        scheme: Colours.schemeEnum(Configs.colors.scheme)
        onColorsChanged: {
            if (ready)
                root.trackArtColors = colors;
        }
    }

    onCachedArtPathChanged: {
        trackArtColors = fallbackTrackArtColors;
    }

    Item {
        anchors.fill: parent

        Image {
            id: trackArt

            anchors.fill: parent
            source: Players.active?.trackArtUrl
            fillMode: Image.PreserveAspectCrop
            opacity: 0.7
            cache: false
            asynchronous: true
            visible: !!Players.active?.trackArtUrl
            layer.enabled: true
            layer.effect: FastBlur {
                source: trackArt
                radius: Configs.generals.coverBlurRadius
            }

            Behavior on opacity {
                NAnim {}
            }
        }

        Loader {
            id: contentLoader

            anchors.fill: parent
            active: GlobalStates.isQuickSettingsOpen
            asynchronous: true
            sourceComponent: ContentMediaPlayer {
                width: contentLoader.width
                trackArtColors: root.trackArtColors
                formatTime: root.formatTime
            }
        }
    }
}
