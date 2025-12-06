pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Components

Loader {
    id: root

    required property var modelData

    active: GlobalStates.isRecordPanelOpen
    width: 70
    height: 70
    sourceComponent: StyledRect {
        width: 70
        height: 70
        radius: Appearance.rounding.full
        color: Themes.m3Colors.m3PrimaryContainer

        Loader {
            id: icon

            active: root.active
            anchors.centerIn: parent
            width: 70
            height: 70
            sourceComponent: Image {
                id: image
                width: 70
                height: 70
                fillMode: Image.PreserveAspectFit
                cache: true
                asynchronous: true
                sourceSize: Qt.size(70, 70)

                source: {
                    if (root.modelData.thumbnail) {
                        return "file://" + root.modelData.thumbnail;
                    }
                    if (root.modelData.path) {
                        return "file://" + root.modelData.path;
                    }
                    return "";
                }

                onStatusChanged: {
                    if (status === Image.Error) {
                        console.warn("Failed to load image:", source);
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Themes.m3Colors.m3SurfaceVariant
                    visible: image.status === Image.Error || image.status === Image.Null

                    StyledText {
                        anchors.centerIn: parent
                        text: root.modelData.thumbnail ? "📹" : "🖼️"
                        font.pixelSize: 16
                    }
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    running: image.status === Image.Loading
                    visible: running
                    width: 20
                    height: 20
                }
            }
        }
    }
}
