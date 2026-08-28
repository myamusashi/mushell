pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Vast.Clipboard

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Singleton {
    property alias uiState: uiState

    Binding {
        target: ClipboardManager
        property: "activeWindow"
        value: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.appId : ""
    }

    IpcHandler {
        target: "clipboard"

        function list(): string {
            return JSON.stringify(ClipboardManager.model.entries());
        }

        function status(): string {
            return JSON.stringify({
                enabled: ClipboardManager.enabled,
                count: ClipboardManager.model.count,
                maxEntries: ClipboardManager.maxEntries
            });
        }

        function remove(id: int): void {
            ClipboardManager.remove(id);
        }

        function clear(): bool {
            return ClipboardManager.clearAll();
        }

        function search(query: string): void {
            ClipboardManager.model.setFilter(query);
        }
    }

    QtObject {
        id: uiState

        readonly property int listWidth: Configs.clipboard.width
        readonly property int previewWidth: 400
        property bool previewFocused: false
        property bool visualActive: false
        property int visualAnchor: 0
    }

    Connections {
        target: GlobalStates

        function onIsClipboardOpenChanged() {
            if (!GlobalStates.isClipboardOpen)
                uiState.visualActive = false;
        }
    }

    FileView {
        path: `${Paths.cacheDir}/clipboard.db`
        watchChanges: false
        onLoaded: ClipboardManager.initialize(`${Paths.cacheDir}/clipboard.db`)
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                ToastService.show(qsTr("Clipboard database not found, created it"), qsTr("Clipboard"), "edit-paste");
                ClipboardManager.initialize(`${Paths.cacheDir}/clipboard.db`);
            }
        }
    }
}
