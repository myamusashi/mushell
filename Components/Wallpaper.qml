import QtQuick

import qs.Helpers
import qs.Services

Image {
    id: wallpaper

    anchors.fill: parent
    source: Paths.currentWallpaper
    sourceSize: Qt.size(Hypr.focusedMonitor.width, Hypr.focusedMonitor.height)
    fillMode: Image.PreserveAspectCrop
    retainWhileLoading: true
    antialiasing: true
    asynchronous: true
    smooth: true
    onStatusChanged: {
        if (this.status == Image.Error) {
            console.log("[ERROR] Wallpaper source invalid");
            console.log("[INFO] Please disable set wallpaper if not required");
        }
    }
}
