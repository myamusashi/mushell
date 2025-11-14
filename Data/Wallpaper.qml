import QtQuick

import qs.Data

Image {
    anchors.fill: parent
    source: Paths.currentWallpaper
    fillMode: Image.PreserveAspectCrop
    retainWhileLoading: true
    antialiasing: true
    asynchronous: true
    smooth: true

    onStatusChanged: {
        if (this.status == Image.Error) {
            console.log("[ERROR] Wallpaper source invalid")
            console.log("[INFO] Please disable set wallpaper if not required")
        }
    }
}
