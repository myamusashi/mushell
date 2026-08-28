pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

PathView {
    id: root

    required property var controller
    required property var visibleWallpapers
    required property var thumbnailAvailability

    readonly property real unitWidth: width / (Configs.wallpaper.visibleWallpaper + 1)

    function selectCurrentWallpaper(): void {
        const list = root.visibleWallpapers ?? [];
        const idx = list.indexOf(Paths.currentWallpaper);
        currentIndex = idx !== -1 ? idx : 0;
    }

    function moveCurrentIndex(step: int): void {
        if (count === 0)
            return;
        currentIndex = (currentIndex + step + count) % count;
    }

    model: ScriptModel {
        values: root.visibleWallpapers ?? []
    }
    pathItemCount: Configs.wallpaper.visibleWallpaper
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    clip: true
    cacheItemCount: Configs.wallpaper.visibleWallpaper + 2

    onCurrentIndexChanged: {
        if (Configs.wallpaper.livePreview && count > 0)
            GlobalStates.previewWallpaper = (root.visibleWallpapers ?? [])[currentIndex] ?? "";
    }
    Component.onCompleted: {
        Qt.callLater(() => root.selectCurrentWallpaper());
    }

    Connections {
        target: WallpaperFileModels

        function onFilteredWallpaperListChanged(): void {
            root.selectCurrentWallpaper();
        }
    }

    path: Path {
        startX: 0
        startY: root.height / 2

        PathLine {
            x: root.width
            y: root.height / 2
        }
    }

    delegate: Card {
        isCurrent: PathView.isCurrentItem
        thumbnailAvailability: root.thumbnailAvailability
        unitWidth: root.unitWidth
        carouselHeight: root.height
        controller: root.controller

        onSelectRequested: idx => root.currentIndex = idx
        onActivateRequested: path => {
            if (root.controller.isVideo(path))
                root.controller.setVideoWallpaper(path);
            else
                root.controller.setWallpaper(path, path);
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.isWallpaperSwitcherOpen = false;
            event.accepted = true;
        }
    }
}
