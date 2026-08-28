pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import Vast.ImageCache

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize - 0.05 : 0 // no gap
    }

    implicitWidth: parent.width * 0.6
    implicitHeight: GlobalStates.isWallpaperSwitcherOpen ? parent.height * 0.3 : 0
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    Component.onCompleted: Wallpaper.requestThumbnailChecks()

    property bool isWallpaperSwitcherOpen: GlobalStates.isWallpaperSwitcherOpen

    onIsWallpaperSwitcherOpenChanged: {
        if (!isWallpaperSwitcherOpen) {
            GlobalStates.previewWallpaper = "";
            return;
        }
        Wallpaper.wallpaperType = Wallpaper.isVideo(Paths.currentWallpaper) ? 1 : 0;
    }

    Image {
        id: colorSourceImage

        asynchronous: true
        visible: false
        onStatusChanged: {
            if (Wallpaper.pendingVideoPath !== "") {
                if (status === Image.Ready) {
                    const videoPath = Wallpaper.pendingVideoPath;
                    Wallpaper.pendingVideoPath = "";
                    Wallpaper.setWallpaper(videoPath, Wallpaper.thumbnailPathFor(videoPath));
                } else if (status === Image.Error)
                    Wallpaper.pendingVideoPath = "";
            }
        }

        Component.onCompleted: {
            Wallpaper.colorSourceImage = colorSourceImage;
        }
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.BottomRightCorner
        location2: Qt.BottomLeftCorner
        extensionSide: Qt.Horizontal
        active: GlobalStates.isWallpaperSwitcherOpen
    }

    IpcHandler {
        target: "img"

        function set(path: string): void {
            if (!Wallpaper.isVideo(path))
                ImageCache.preload(path, Qt.size(Screen.width, Screen.height));
            Wallpaper.setWallpaper(path, Wallpaper.isVideo(path) ? "" : path);
        }

        function get(): string {
            return Paths.currentWallpaper;
        }
    }

    WrapperRectangle {
        anchors.fill: parent
        color: GlobalStates.drawerColors
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        topRightRadius: Appearance.rounding.normal

        Loader {
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isWallpaperSwitcherOpen // qmllint disable
            asynchronous: true
            sourceComponent: FocusCage {
                active: GlobalStates.isWallpaperSwitcherOpen
                defaultFocus: content.searchField

                anchors.fill: parent
                anchors.margins: Appearance.spacing.normal

                Content {
                    id: content

                    anchors.fill: parent
                    controller: Wallpaper
                }
            }
        }
    }
}
