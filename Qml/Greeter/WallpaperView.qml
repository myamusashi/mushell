pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects

import qs.Services
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

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.alpha(Colours.m3Colors.m3Scrim, 0.45)
            }
            GradientStop {
                position: 0.5
                color: Qt.alpha(Colours.m3Colors.m3Scrim, 0.25)
            }
            GradientStop {
                position: 1.0
                color: Qt.alpha(Colours.m3Colors.m3Scrim, 0.6)
            }
        }
    }
}
