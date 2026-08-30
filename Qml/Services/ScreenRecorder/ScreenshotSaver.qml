import QtQuick
import Quickshell.Io

import "shellUtils.js" as Utils

Item {
    id: root

    required property string screenshotDir

    signal saved(string path)
    signal copied
    signal failed(string reason)

    function saveResult(result, action) {
        if (!result || !result.saveToFile) {
            failed("Invalid grab result");
            return;
        }

        const path = Utils.screenshotPath(screenshotDir);
        if (!result.saveToFile(path)) {
            failed("Failed to save screenshot to " + path);
            return;
        }

        if (action === "save" || action === "save+copy")
            saved(path);

        if (action === "copy" || action === "save+copy")
            copyFile(path);
    }

    function copyFile(path) {
        wlCopy.imgPath = path;
        wlCopy.running = true;
    }

    Process {
        id: wlCopy

        property string imgPath

        command: {
            const p = imgPath;
            if (!p)
                return ["true"];
            return ["sh", "-c", "cat '" + p.replace(/'/g, "'\\''") + "' | wl-copy"];
        }

        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            if (code === 0)
                root.copied();
            else
                root.failed("wl-copy exited with code " + code);
        }
    }
}
