import QtQuick
import Quickshell.Io

JsonObject {
    property bool enabledWallpaper: true
    property string wallpaperDir: "/home/myamusashi/Pictures/wallpapers"
    property string transition: "random"
    property int visibleWallpaper: 3
    property bool transitionLowPerfMode: false
    property int transitionDuration: 300
    property bool depthWallpaperEnabled: true
    property bool livePreview: true
    property bool autoProcessedDepthWallpaper: false
    property string depthWallpaperSource: ""
    property string depthFgPath: ""
}
