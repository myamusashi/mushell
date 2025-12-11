pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Io

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Loader {
    id: root

    required property var modelData
    property string thumbnailPath: ""
    property bool showLoading: true

    function getFileExtension(filepath) {
        const filename = filepath.split('/').pop();
        const lastDot = filename.lastIndexOf('.');
        if (lastDot === -1 || lastDot === 0)
            return '';
        return filename.substring(lastDot + 1).toLowerCase();
    }

    active: GlobalStates.isRecordPanelOpen
    width: 70
    height: 70

    Component.onCompleted: {
        const ext = getFileExtension(root.modelData.path);
        const videoFormats = ["mkv", "mp4", "webm", "avi"];

        if (videoFormats.includes(ext))
            createThumbnails.running = true;
        else
            thumbnailPath = "file://" + root.modelData.path;
    }

    sourceComponent: StyledRect {
        width: 70
        height: 70
        radius: Appearance.rounding.full
        color: Colours.m3Colors.m3PrimaryContainer

        Image {
            id: image

            anchors.centerIn: parent
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            sourceSize: Qt.size(60, 60)
            source: root.thumbnailPath

            Rectangle {
                anchors.fill: parent
                color: Colours.m3Colors.m3SurfaceVariant
                visible: image.status === Image.Error || image.status === Image.Null
                radius: parent.width / 2

                StyledText {
                    anchors.centerIn: parent
                    text: {
                        const ext = root.getFileExtension(root.modelData.path);
                        const videoFormats = ["mkv", "mp4", "webm", "avi"];
                        return videoFormats.includes(ext) ? "📹" : "🖼️";
                    }
                    font.pixelSize: Appearance.fonts.large
                }
            }

            LoadingIndicator {
                implicitWidth: 30
                implicitHeight: 30
				status: {
					if (root.getFileExtension(root.modelData.path) === "mkv" ||root.getFileExtension(root.modelData.path) === "mp4")
						return root.showLoading || image.status == Image.Loading
					else
						return image.status == Image.Loading
				}
            }
        }
    }

    Process {
        id: createThumbnails

        running: false
        command: ["sh", "-c", `${Quickshell.shellDir}/Assets/create-thumbnails.sh "${root.modelData.path}" "${Paths.cacheDir}/video-thumbnails"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim();
                delayTimer.thumbnailData = data;
                delayTimer.start();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.error("Thumbnail generation error:", text);
            }
        }
    }

    Timer {
		id: delayTimer

        interval: 500
        repeat: false
        property string thumbnailData: ""

        onTriggered: {
            root.thumbnailPath = thumbnailData;
            root.showLoading = false;
        }
    }
}
