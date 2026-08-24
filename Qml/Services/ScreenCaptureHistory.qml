pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Utils // qmllint disable
import qs.Services

Singleton {
    id: root

    property string videosPath: ""
    property string screenshotPath: ""
    property list<var> screenshotFiles
    property list<var> screenrecordFiles

    function parseFileList(jsonText) {
        try {
            const lines = jsonText.trim().split('\n').filter(line => line.length > 0);
            return lines.map(line => JSON.parse(line));
        } catch (e) {
            console.error("Failed to parse file metadata:", e);
            ToastService.show(qsTr("Failed to parse file metadata: %1").arg(e), qsTr("Screen Capture"), "camera-photo-symbolic", 3000);
            return [];
        }
    }

    function newestFiles(jsonText) {
        const data = jsonText.trim();
        if (!data)
            return [];

        const files = parseFileList(data);
        files.sort((a, b) => b.created - a.created);
        return files.slice(0, 10);
    }

    function reloadFiles(): void {
        getScreenshotFilesMetadata.started();
        getScreenrecordFilesMetadata.started();
    }

    Process {
        id: getScreenshotFilesMetadata

        running: true
        command: ["sh", "-c", `find "${root.screenshotPath || Paths.home + '/Pictures/screenshot'}" -maxdepth 1 -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \\) -printf '{"path":"%p","name":"%f","size":%s,"created":%C@}\\n'`]
        stdout: StdioCollector {
            onStreamFinished: root.screenshotFiles = root.newestFiles(text)
        }
    }

    Process {
        id: getScreenrecordFilesMetadata

        running: true
        command: ["sh", "-c", `find "${root.videosPath || Paths.videos + "/Shell"}" -maxdepth 1 -type f \\( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" \\) -printf '{"path":"%p","name":"%f","size":%s,"created":%C@}\\n'`]
        stdout: StdioCollector {
            onStreamFinished: root.screenrecordFiles = root.newestFiles(text)
        }
    }
}
