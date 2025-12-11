pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

import qs.Helpers
import qs.Services

Singleton {
    id: root

    // TODO: Yeah not now, add this values when i want to create Settings windows
    property string videosPath
    property string screenshotPath
    property list<var> screenshotFiles
    property list<var> screenrecordFiles

    function parseFileList(jsonText) {
        try {
            const lines = jsonText.trim().split('\n').filter(line => line.length > 0);
            return lines.map(line => JSON.parse(line));
        } catch (e) {
            console.error("Failed to parse file metadata:", e);
            return [];
        }
    }

    function reloadFiles(): void {
        getScreenshotFilesMetadata.started();
        getScreenrecordFilesMetadata.started();
    }

    Process {
        id: getScreenshotFilesMetadata

        running: true
        command: ["sh", "-c", `find "${root.screenshotPath || Paths.home + '/Pictures/screenshot'}" -maxdepth 1 -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \\) -printf '{"path":"%p","name":"%f","size":%s,"created":%C@}\\n' | sort -t: -k2 -rn | head -10`]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim();
                if (data)
                root.screenshotFiles = root.parseFileList(data);
            }
        }
    }

    // TODO: created thumbnails
    Process {
        id: getScreenrecordFilesMetadata

        running: true
        command: ["sh", "-c", `find "${root.videosPath || Paths.videos + "/Shell"}" -maxdepth 1 -type f \\( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" \\) -printf '{"path":"%p","name":"%f","size":%s,"created":%C@}\\n' | sort -t: -k2 -rn | head -10`]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim();
                if (data)
                root.screenrecordFiles = root.parseFileList(data);
            }
        }
    }
}
