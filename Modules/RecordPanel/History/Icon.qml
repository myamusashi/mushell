pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Configs
import qs.Helpers
import qs.Components

Loader {
    id: root
    required property var modelData
    property string thumbnailPath: ""

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
        color: Themes.m3Colors.m3PrimaryContainer

        Image {
            id: image
            anchors.centerIn: parent
            width: 60
            height: 60
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            sourceSize: Qt.size(60, 60)
            source: root.thumbnailPath

            Rectangle {
                anchors.fill: parent
                color: Themes.m3Colors.m3SurfaceVariant
                visible: image.status === Image.Error || image.status === Image.Null
                radius: parent.width / 2

                StyledText {
                    anchors.centerIn: parent
                    text: {
                        const ext = root.getFileExtension(root.modelData.path);
                        const videoFormats = ["mkv", "mp4", "webm", "avi"];
                        return videoFormats.includes(ext) ? "📹" : "🖼️";
                    }
                    font.pixelSize: 24
                }
			}

			LoadingIndicator {
				status: image.status === Image.Loading
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
                root.thumbnailPath = data;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.error("Thumbnail generation error:", text);
            }
        }
    }
}
