import QtQuick
import Quickshell.Io

JsonObject {
    property bool enabled: false
    property bool enablePreview: false
    property bool enableVimKeybinds: false
    property bool keepOpenAfterCopy: false
    property Preview preview: Preview {}
    property int listEntries: 15
    property int maxEntries: 300
    property real width: 300
    property real height: 400

    component Preview: JsonObject {
        property real sourceWidth: 300
        property real sourceHeight: 300
        property real sourceSizeWidth: sourceWidth
        property real sourceSizeHeight: sourceHeight
    }
}
