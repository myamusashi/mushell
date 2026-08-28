pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Vast.Clipboard

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base

WrapperRectangle {
    id: root

    anchors.centerIn: parent

    signal closeRequested

    implicitWidth: uiState.listWidth + (Configs.clipboard.enablePreview ? (uiState.previewWidth + Appearance.spacing.small * 2) : 0)
    implicitHeight: GlobalStates.isClipboardOpen ? Configs.clipboard.height : 0
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable
    radius: Appearance.rounding.normal
    color: Colours.m3Colors.m3SurfaceContainerLow
    clip: true

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

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

    Loader {
        active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isClipboardOpen // qmllint disable
        asynchronous: true
        sourceComponent: FocusCage {
            active: GlobalStates.isClipboardOpen
            defaultFocus: Configs.clipboard.enableVimKeybinds ? vimFocus : content.searchField
            anchors.fill: parent

            Item {
                id: vimFocus

                width: 0
                height: 0
                Keys.onPressed: event => content.handleKey(event)
            }

            Content {
                id: content

                anchors.fill: parent
                uiState: uiState
            }
        }
    }
}
