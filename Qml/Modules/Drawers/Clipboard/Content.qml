pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Clipboard

import qs.Core.Configs
import qs.Core.States
import qs.Services

ColumnLayout {
    id: root

    required property var uiState

    readonly property int currentId: {
        if (entryGrid.entryList.currentIndex < 0 || !entryGrid.entryList.currentItem)
            return -1;
        return entryGrid.entryList.currentItem.entryId; // qmllint disable
    }

    property alias searchField: searchBar.searchField
    property alias entryList: entryGrid.entryList

    spacing: 0

    function handleKey(event: var): void {
        if (searchBar.searchField.isFocused) {
            if (!searchBar.searchField.hasSelection && event.key === Qt.Key_Escape) {
                root.forceActiveFocus();
                event.accepted = true;
            }
            return;
        }

        const vim = Configs.clipboard.enableVimKeybinds;

        if (vim) {
            if (event.key === Qt.Key_Slash) {
                searchBar.searchField.requestKeyboardFocus();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Escape && root.uiState.visualActive) {
                root.uiState.visualActive = false;
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_V) {
                root.uiState.visualActive = !root.uiState.visualActive;
                if (root.uiState.visualActive)
                    root.uiState.visualAnchor = entryGrid.entryList.currentIndex;
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_J) {
                entryGrid.entryList.moveCurrentIndexDown();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_K) {
                entryGrid.entryList.moveCurrentIndexUp();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_H) {
                entryGrid.entryList.moveCurrentIndexLeft();
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_L) {
                entryGrid.entryList.moveCurrentIndexRight();
                event.accepted = true;
                return;
            }

            if (root.uiState.visualActive && event.key === Qt.Key_Y) {
                const ids = entryGrid.entryList.visualSelectedIds();
                const copied = ids.length > 0 && ClipboardManager.copySelection(ids);
                if (copied) {
                    const n = ids.length === 1 ? qsTr("entry") : qsTr("entries");
                    ToastService.show(qsTr("Copied %1 %2").arg(ids.length).arg(n), qsTr("Clipboard"), "edit-paste");
                    if (!Configs.clipboard.keepOpenAfterCopy)
                        GlobalStates.isClipboardOpen = false;
                }
                root.uiState.visualActive = false;
                event.accepted = true;
                return;
            }

            if (root.uiState.visualActive && event.key === Qt.Key_D) {
                const ids = entryGrid.entryList.visualSelectedIds();
                const removed = ClipboardManager.removeMany(ids);
                if (removed > 0) {
                    const n = removed === 1 ? qsTr("entry") : qsTr("entries");
                    ToastService.show(qsTr("Deleted %1 %2").arg(removed).arg(n), qsTr("Clipboard"), "edit-delete");
                }
                root.uiState.visualActive = false;
                entryGrid.entryList.currentIndex = Math.min(entryGrid.entryList.currentIndex, entryGrid.entryList.count - 1);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Y && root.currentId >= 0) {
                ClipboardManager.copyToClipboard(root.currentId);
                if (!Configs.clipboard.keepOpenAfterCopy)
                    GlobalStates.isClipboardOpen = false;
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_D) {
                const item = entryGrid.entryList.currentItem;
                if (root.currentId >= 0 && item && !item.pinned) // qmllint disable
                    ClipboardManager.remove(root.currentId);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_P) {
                const item = entryGrid.entryList.currentItem;
                if (root.currentId >= 0 && item)
                    ClipboardManager.pin(root.currentId, !item.pinned); // qmllint disable
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Q) {
                GlobalStates.isClipboardOpen = false;
                event.accepted = true;
                return;
            }
        }

        if (event.key === Qt.Key_Up) {
            entryGrid.entryList.moveCurrentIndexUp();
            event.accepted = true;
        }

        if (event.key === Qt.Key_Down) {
            entryGrid.entryList.moveCurrentIndexDown();
            event.accepted = true;
        }

        if (event.key === Qt.Key_Left) {
            entryGrid.entryList.moveCurrentIndexLeft();
            event.accepted = true;
        }

        if (event.key === Qt.Key_Right) {
            entryGrid.entryList.moveCurrentIndexRight();
            event.accepted = true;
        }

        if (event.key === Qt.Key_Q && !vim) {
            GlobalStates.isClipboardOpen = false;
            event.accepted = true;
        }

        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_T) {
            Configs.clipboard.enablePreview = !Configs.clipboard.enablePreview;
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Delete && !vim) {
            const item = entryGrid.entryList.currentItem;
            if (root.currentId >= 0 && item && !item.pinned) // qmllint disable
                ClipboardManager.remove(root.currentId);
            event.accepted = true;
        }

        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P && !vim) {
            const item = entryGrid.entryList.currentItem;
            if (root.currentId >= 0 && item)
                ClipboardManager.pin(root.currentId, !item.pinned); // qmllint disable
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Tab) {
            root.uiState.previewFocused = true;
            event.accepted = true;
        }
    }

    SearchBar {
        id: searchBar

        Layout.fillWidth: true
        entryList: entryGrid.entryList
        uiState: root.uiState
        currentId: root.currentId
        onKeyPressed: event => root.handleKey(event)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.small

        EntryGrid {
            id: entryGrid

            Layout.preferredWidth: root.uiState.listWidth
            Layout.fillHeight: true
            uiState: root.uiState
            searchText: searchBar.searchField.text
        }

        Loader {
            id: previewLoader

            Layout.fillWidth: true
            Layout.fillHeight: true
            active: Configs.clipboard.enablePreview
            visible: active

            sourceComponent: RowLayout {
                anchors.fill: parent
                spacing: Appearance.spacing.small

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
                }

                Preview {
                    Layout.preferredWidth: root.uiState.previewWidth
                    Layout.fillHeight: true
                    entryId: root.currentId
                    onCopyRequested: id => ClipboardManager.copyToClipboard(id)
                    onPinToggled: (id, pinned) => ClipboardManager.pin(id, pinned)
                }
            }
        }
    }
}
