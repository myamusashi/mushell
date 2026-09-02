import QtQuick

import Quickshell.Io

JsonObject {
    property int maxFps: 60
    property string bitrate: "5 MB"
    property string videoCodec: ""
    property string audioCodec: ""
    property string lowPower: "auto"
    property bool showCursor: true
    property bool historyMode: false
}
