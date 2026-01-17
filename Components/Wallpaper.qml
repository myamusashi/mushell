import QtQuick

import qs.Helpers

Image {
    id: wallpaper

    anchors.fill: parent
    source: Paths.currentWallpaper
    sourceSize: Qt.size(parent.width, parent.height)
    fillMode: Image.PreserveAspectCrop
    retainWhileLoading: true
    onStatusChanged: {
        if (this.status == Image.Error) {
            console.log("[ERROR] Wallpaper source invalid");
            console.log("[INFO] Please disable set wallpaper if not required");
        }
    }
}
