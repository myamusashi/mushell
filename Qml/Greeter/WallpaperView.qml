pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects

import qs.Core.Utils

Item {
    id: root

    property real wallpaperOpacity: 0
    property real blurRadius: 12
    property alias effectSource: wallpaperLayer

    Item {
        id: wallpaperLayer

        anchors.fill: parent
        opacity: root.wallpaperOpacity
        layer.enabled: true
        layer.effect: FastBlur {
            radius: root.blurRadius
            transparentBorder: false
        }

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl(`${Paths.projectRoot}/Assets/images/wallpaper.png`)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }
}
