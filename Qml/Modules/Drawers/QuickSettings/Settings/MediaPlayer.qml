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
            command = ["curl", "-sLz", targetPath, "-o", targetPath, url];
            running = true;
        }

        onExited: function (exitCode) { // qmllint disable
            if (exitCode === 0)
                root.cachedArtPath = targetPath;
        }
    }

    Connections {
        target: Players

        function onIndexChanged() {
            const url = Players.active?.trackArtUrl ?? "";
            url.startsWith("http") ? artDownloader.download(url) : root.cachedArtPath = url;
        }
    }

    Connections {
        target: Players.active

        function onTrackChanged() {
            const url = Players.active?.trackArtUrl ?? "";
            if (url.startsWith("http"))
                artDownloader.download(url);
            else
                root.cachedArtPath = url;

            const localPath = url.replace("file://", "");
            if (localPath && !url.startsWith("http"))
                ImageCache.copyAndPreload(localPath, Qt.size(300, 300));
        }
    }

    Connections {
        target: ColorGenerator

        function onColorsReady(imagePath, colors) {
            if (imagePath === root.cachedArtPath.replace(/^file:\/\//, ""))
                root.trackArtColors = colors;
        }
    }

    onCachedArtPathChanged: {
        trackArtColors = fallbackTrackArtColors;
        if (cachedArtPath !== "")
            ColorGenerator.generateColors(cachedArtPath.replace(/^file:\/\//, ""), Configs.colors.scheme);
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
