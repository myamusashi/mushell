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
        if (!entryGrid || !entryGrid.entryList || entryGrid.entryList.currentIndex < 0 || !entryGrid.entryList.currentItem)
            return -1;
        return entryGrid.entryList.currentItem.entryId; // qmllint disable
    }

    property alias searchField: searchBar.searchField
    property alias entryList: entryGrid.entryList

    spacing: 0

    function handleKey(event: var): void {
        if (!entryGrid || !entryGrid.entryList)
            return;

        const navKeys = [Qt.Key_Up, Qt.Key_Down, Qt.Key_Left, Qt.Key_Right, Qt.Key_Tab];
        const isNavKey = navKeys.indexOf(event.key) !== -1;

        if (searchBar.searchField.isFocused) {
            if (!searchBar.searchField.hasSelection && event.key === Qt.Key_Escape) {
                root.forceActiveFocus();
                event.accepted = true;
                return;
            }
            if (!isNavKey)
                return;
        }

        const vim = Configs.clipboard.enableVimKeybinds;
        const item = entryGrid.entryList.currentItem;

        switch (event.key) {
        case Qt.Key_Slash:
            if (vim) {
                searchBar.searchField.requestKeyboardFocus();
                event.accepted = true;
            }
            break;
        case Qt.Key_Escape:
            if (vim && root.uiState.visualActive) {
                root.uiState.visualActive = false;
                event.accepted = true;
            }
            break;
        case Qt.Key_V:
            if (vim) {
                root.uiState.visualActive = !root.uiState.visualActive;
                if (root.uiState.visualActive)
                    root.uiState.visualAnchor = entryGrid.entryList.currentIndex;
                event.accepted = true;
            }
            break;
        case Qt.Key_J:
            if (vim) {
                entryGrid.entryList.moveCurrentIndexDown();
                event.accepted = true;
            }
            break;
        case Qt.Key_K:
            if (vim) {
                entryGrid.entryList.moveCurrentIndexUp();
                event.accepted = true;
            }
            break;
        case Qt.Key_H:
            if (vim) {
                entryGrid.entryList.moveCurrentIndexLeft();
                event.accepted = true;
            }
            break;
        case Qt.Key_L:
            if (vim) {
                entryGrid.entryList.moveCurrentIndexRight();
                event.accepted = true;
            }
            break;
        case Qt.Key_Y:
            if (vim) {
                if (root.uiState.visualActive) {
                    const ids = entryGrid.entryList.visualSelectedIds();
                    const copied = ids.length > 0 && ClipboardManager.copySelection(ids);
                    if (copied) {
                        const n = ids.length === 1 ? qsTr("entry") : qsTr("entries");
                        ToastService.show(qsTr("Copied %1 %2").arg(ids.length).arg(n), qsTr("Clipboard"), "edit-paste");
                        if (!Configs.clipboard.keepOpenAfterCopy)
                            GlobalStates.isClipboardOpen = false;
                    }
                    root.uiState.visualActive = false;
                } else if (root.currentId >= 0) {
                    ClipboardManager.copyToClipboard(root.currentId);
                    if (!Configs.clipboard.keepOpenAfterCopy)
                        GlobalStates.isClipboardOpen = false;
                }
                event.accepted = true;
            }
            break;
        case Qt.Key_D:
            if (vim) {
                if (root.uiState.visualActive) {
                    const ids = entryGrid.entryList.visualSelectedIds();
                    const removed = ClipboardManager.removeMany(ids);
                    if (removed > 0) {
                        const n = removed === 1 ? qsTr("entry") : qsTr("entries");
                        ToastService.show(qsTr("Deleted %1 %2").arg(removed).arg(n), qsTr("Clipboard"), "edit-delete");
                    }
                    root.uiState.visualActive = false;
                    entryGrid.entryList.currentIndex = Math.min(entryGrid.entryList.currentIndex, entryGrid.entryList.count - 1);
                } else if (root.currentId >= 0 && item && !item.pinned) { // qmllint disable
                    ClipboardManager.remove(root.currentId);
                }
                event.accepted = true;
            }
            break;
        case Qt.Key_P:
            if (vim) {
                if (root.currentId >= 0 && item)
                    ClipboardManager.pin(root.currentId, !item.pinned); // qmllint disable
                event.accepted = true;
            } else if ((event.modifiers & Qt.ControlModifier) && !vim) {
                if (root.currentId >= 0 && item)
                    ClipboardManager.pin(root.currentId, !item.pinned); // qmllint disable
                event.accepted = true;
            }
            break;
        case Qt.Key_Q:
            GlobalStates.isClipboardOpen = false;
            event.accepted = true;
            break;
        case Qt.Key_Up:
            entryGrid.entryList.moveCurrentIndexUp();
            event.accepted = true;
            break;
        case Qt.Key_Down:
            entryGrid.entryList.moveCurrentIndexDown();
            event.accepted = true;
            break;
        case Qt.Key_Left:
            entryGrid.entryList.moveCurrentIndexLeft();
            event.accepted = true;
            break;
        case Qt.Key_Right:
            entryGrid.entryList.moveCurrentIndexRight();
            event.accepted = true;
            break;
        case Qt.Key_T:
            if (event.modifiers & Qt.ControlModifier) {
                Configs.clipboard.enablePreview = !Configs.clipboard.enablePreview;
                event.accepted = true;
            }
            break;
        case Qt.Key_Delete:
            if (!vim) {
                if (root.currentId >= 0 && item && !item.pinned) // qmllint disable
                    ClipboardManager.remove(root.currentId);
                event.accepted = true;
            }
            break;
        case Qt.Key_Tab:
            root.uiState.previewFocused = true;
            event.accepted = true;
            break;
        default:
            break;
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
