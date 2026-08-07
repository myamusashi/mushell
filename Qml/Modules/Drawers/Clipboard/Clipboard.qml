pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    // visualStart/visualEnd are computed on the GridView (entryList), which is
    // where the selected row range is known.

    implicitWidth: d.listWidth + (Configs.clipboard.enablePreview ? (d.previewWidth + Appearance.spacing.small * 2) : 0)
    implicitHeight: GlobalStates.isClipboardOpen ? Configs.clipboard.height : 0
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

    QtObject {
        id: d

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
                d.visualActive = false;
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
        sourceComponent: clipboardWindow
    }

    Component {
        id: clipboardWindow

        FocusCage {
            active: GlobalStates.isClipboardOpen
            defaultFocus: searchField
            anchors.fill: parent

            ColumnLayout {
                id: clipboardLayout

                anchors.fill: parent

                readonly property int currentId: {
                    if (entryList.currentIndex < 0 || !entryList.currentItem)
                        return -1;
                    return entryList.currentItem.entryId; // qmllint disable
                }

                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: Appearance.margin.large
                            rightMargin: Appearance.margin.large
                            topMargin: Appearance.margin.smaller
                            bottomMargin: Appearance.margin.smaller
                        }
                        spacing: Appearance.spacing.smaller

                        Icon {
                            id: searchIcon
                            property color target: searchField.activeFocus ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                            property color cFrom
                            property color cTo
                            property bool cActive: false
                            property real cBlend: 1.0
                            onCBlendChanged: {
                                if (!cActive)
                                    return;
                                if (cBlend >= 1) {
                                    color = cTo;
                                    cActive = false;
                                } else if (cBlend > 0) {
                                    color = Colours.blendColors(cFrom, cTo, cBlend);
                                }
                            }
                            onTargetChanged: {
                                cAnim.stop();
                                cFrom = color;
                                cTo = target;
                                cActive = true;
                                cBlend = 0.0;
                                cAnim.start();
                            }

                            icon: "search"
                            font.pixelSize: Appearance.fonts.size.larger

                            NAnim {
                                id: cAnim
                                target: searchIcon
                                property: "cBlend"
                                from: 0.0
                                to: 1.0
                            }
                        }

                        StyledTextInput {
                            id: searchField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 35

                            placeHolderText: qsTr("Search clipboard…")

                            Timer {
                                id: searchDebounce

                                interval: 150
                                repeat: false
                                onTriggered: ClipboardManager.model.setFilter(searchField.text)
                            }

                            onTextChanged: {
                                if (text.length === 0) {
                                    searchDebounce.stop();
                                    ClipboardManager.model.setFilter("");
                                } else {
                                    searchDebounce.restart();
                                }
                            }
                            toggleButtonVisible: false

                            onAccepted: {
                                if (Configs.clipboard.enableVimKeybinds) {
                                    // Copy moved to "y" in vim mode.
                                    return;
                                }

                                if (clipboardLayout.currentId >= 0) {
                                    ClipboardManager.copyToClipboard(clipboardLayout.currentId);
                                    if (!Configs.clipboard.keepOpenAfterCopy)
                                        GlobalStates.isClipboardOpen = false;
                                }
                            }

                            onKeyPressed: event => {
                                const vim = Configs.clipboard.enableVimKeybinds;

                                // Vim mode: letter keys act as commands instead of
                                // text input, so they are consumed here.
                                if (vim) {
                                    if (event.key === Qt.Key_Escape && d.visualActive) {
                                        d.visualActive = false;
                                        event.accepted = true;
                                        return;
                                    }

                                    if (event.key === Qt.Key_V) {
                                        d.visualActive = !d.visualActive;
                                        if (d.visualActive)
                                            d.visualAnchor = entryList.currentIndex;
                                        event.accepted = true;
                                        return;
                                    }

                                    if (event.key === Qt.Key_J) {
                                        entryList.moveCurrentIndexDown();
                                        event.accepted = true;
                                        return;
                                    }

                                    if (event.key === Qt.Key_K) {
                                        entryList.moveCurrentIndexUp();
                                        event.accepted = true;
                                        return;
                                    }

                                    if (event.key === Qt.Key_H) {
                                        entryList.moveCurrentIndexLeft();
                                        event.accepted = true;
                                        return;
                                    }

                                    if (event.key === Qt.Key_L) {
                                        entryList.moveCurrentIndexRight();
                                        event.accepted = true;
                                        return;
                                    }

                                    if (d.visualActive && event.key === Qt.Key_Y) {
                                        const ids = entryList.visualSelectedIds();
                                        const copied = ids.length > 0 && ClipboardManager.copySelection(ids);
                                        if (copied) {
                                            const n = ids.length === 1 ? qsTr("entry") : qsTr("entries");
                                            ToastService.show(qsTr("Copied %1 %2").arg(ids.length).arg(n), qsTr("Clipboard"), "edit-paste");
                                            if (!Configs.clipboard.keepOpenAfterCopy)
                                                GlobalStates.isClipboardOpen = false;
                                        }
                                        d.visualActive = false;
                                        event.accepted = true;
                                        return;
                                    }

                                    if (d.visualActive && event.key === Qt.Key_D) {
                                        const ids = entryList.visualSelectedIds();
                                        const removed = ClipboardManager.removeMany(ids);
                                        if (removed > 0) {
                                            const n = removed === 1 ? qsTr("entry") : qsTr("entries");
                                            ToastService.show(qsTr("Deleted %1 %2").arg(removed).arg(n), qsTr("Clipboard"), "edit-delete");
                                        }
                                        d.visualActive = false;
                                        entryList.currentIndex = Math.min(entryList.currentIndex, entryList.count - 1);
                                        event.accepted = true;
                                        return;
                                    }

                                    if (event.key === Qt.Key_Y && clipboardLayout.currentId >= 0) {
                                        ClipboardManager.copyToClipboard(clipboardLayout.currentId);
                                        if (!Configs.clipboard.keepOpenAfterCopy)
                                            GlobalStates.isClipboardOpen = false;
                                        event.accepted = true;
                                        return;
                                    }

                                    if (event.key === Qt.Key_D) {
                                        const item = entryList.currentItem;
                                        if (clipboardLayout.currentId >= 0 && item && !item.pinned) // qmllint disable
                                            ClipboardManager.remove(clipboardLayout.currentId);
                                        event.accepted = true;
                                        return;
                                    }

                                    if (event.key === Qt.Key_P) {
                                        const item = entryList.currentItem;
                                        if (clipboardLayout.currentId >= 0 && item)
                                            ClipboardManager.pin(clipboardLayout.currentId, !item.pinned); // qmllint disable
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
                                    entryList.moveCurrentIndexUp();
                                    event.accepted = true;
                                }

                                if (event.key === Qt.Key_Down) {
                                    entryList.moveCurrentIndexDown();
                                    event.accepted = true;
                                }

                                if (event.key === Qt.Key_Left) {
                                    entryList.moveCurrentIndexLeft();
                                    event.accepted = true;
                                }

                                if (event.key === Qt.Key_Right) {
                                    entryList.moveCurrentIndexRight();
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
                                    const item = entryList.currentItem;
                                    if (clipboardLayout.currentId >= 0 && item && !item.pinned) // qmllint disable
                                        ClipboardManager.remove(clipboardLayout.currentId);
                                    event.accepted = true;
                                }

                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P && !vim) {
                                    const item = entryList.currentItem;
                                    if (clipboardLayout.currentId >= 0 && item)
                                        ClipboardManager.pin(clipboardLayout.currentId, !item.pinned); // qmllint disable
                                    event.accepted = true;
                                    return;
                                }

                                if (event.key === Qt.Key_Tab) {
                                    d.previewFocused = true;
                                    event.accepted = true;
                                }
                            }
                        }

                        StyledText {
                            text: (entryList.currentPage + 1) + " / " + entryList.totalPages
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            visible: entryList.totalPages > 0 && searchField.text.length === 0 && !d.visualActive
                        }

                        StyledText {
                            text: qsTr("VISUAL") + " " + entryList.visualSelectableCount
                            font.pixelSize: Appearance.fonts.size.small
                            font.bold: true
                            color: Colours.m3Colors.m3Primary
                            visible: d.visualActive
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Appearance.spacing.small

                    Item {
                        Layout.preferredWidth: d.listWidth
                        Layout.fillHeight: true

                        Flickable {
                            id: verticalFlick

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                bottom: pageIndicatorRow.top
                                topMargin: Appearance.margin.small
                                bottomMargin: Appearance.margin.small
                            }

                            contentWidth: width
                            contentHeight: entryList.height
                            clip: true
                            flickableDirection: Flickable.VerticalFlick

                            onDraggingChanged: scrollAnim.stop()

                            onDragStarted: scrollAnim.stop()

                            onFlickStarted: scrollAnim.stop()

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            GridView {
                                id: entryList

                                width: verticalFlick.width
                                height: Math.max(1, Configs.clipboard.listEntries) * (64 + Appearance.spacing.small)

                                readonly property int visualStart: d.visualActive ? Math.min(d.visualAnchor, currentIndex) : -1
                                readonly property int visualEnd: d.visualActive ? Math.max(d.visualAnchor, currentIndex) : -1

                                readonly property int visualSelectableCount: {
                                    let n = 0;
                                    for (let i = visualStart; i <= visualEnd; ++i) {
                                        const t = ClipboardManager.model.typeAtRow(i);
                                        if (t === "text" || t === "html")
                                            ++n;
                                    }
                                    return n;
                                }

                                function visualSelectedIds(): var {
                                    const ids = [];
                                    const start = Math.min(d.visualAnchor, currentIndex);
                                    const end = Math.max(d.visualAnchor, currentIndex);
                                    for (let i = start; i <= end; ++i)
                                        ids.push(ClipboardManager.model.idAtRow(i));
                                    return ids;
                                }

                                clip: false
                                currentIndex: 0
                                model: ClipboardManager.model

                                // Pagination setup
                                flow: GridView.FlowTopToBottom
                                cellWidth: width
                                cellHeight: 64 + Appearance.spacing.small
                                snapMode: GridView.SnapOneRow
                                maximumFlickVelocity: 1000
                                boundsBehavior: Flickable.StopAtBounds

                                readonly property int itemsPerPage: Math.max(1, Configs.clipboard.listEntries)
                                readonly property int maxVisibleCount: Math.min(count, Configs.clipboard.maxEntries)
                                readonly property int totalPages: Math.max(1, Math.ceil(maxVisibleCount / itemsPerPage))
                                readonly property int currentPage: Math.max(0, Math.min(totalPages - 1, Math.round(contentX / width)))

                                onContentXChanged: {
                                    var maxContentX = Math.max(0, (totalPages - 1) * width);
                                    if (contentX > maxContentX) {
                                        contentX = maxContentX;
                                    }
                                }

                                function ensureCurrentVisible() {
                                    const itemY = (currentIndex % itemsPerPage) * cellHeight;
                                    const viewport = verticalFlick.height;
                                    const currentY = verticalFlick.contentY;
                                    let targetY = -1;
                                    if (itemY < currentY)
                                        targetY = itemY;
                                    else if (itemY + cellHeight > currentY + viewport)
                                        targetY = itemY + cellHeight - viewport;
                                    if (targetY < 0)
                                        return;
                                    targetY = Math.max(0, Math.min(targetY, verticalFlick.contentHeight - viewport));
                                    scrollAnim.stop();
                                    scrollAnim.to = targetY;
                                    scrollAnim.start();
                                }

                                onCurrentIndexChanged: ensureCurrentVisible()

                                NAnim {
                                    id: scrollAnim

                                    target: verticalFlick
                                    property: "contentY"
                                    duration: Appearance.animations.durations.small
                                }

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AlwaysOff
                                }
                                ScrollBar.horizontal: hbar

                                highlightMoveDuration: 200
                                highlightFollowsCurrentItem: true
                                highlightRangeMode: GridView.ApplyRange
                                highlight: StyledRect {
                                    color: Colours.m3Colors.m3SurfaceContainerHigh
                                    width: entryList.cellWidth
                                    height: entryList.cellHeight
                                }

                                rebound: Transition {
                                    NAnim {
                                        properties: "x,y"
                                    }
                                }

                                add: Transition {
                                    NAnim {
                                        properties: "opacity,scale"
                                        from: 0
                                        to: 1
                                    }
                                }

                                remove: Transition {
                                    NAnim {
                                        properties: "opacity,scale"
                                        from: 1
                                        to: 0
                                    }
                                }

                                move: Transition {
                                    NAnim {
                                        properties: "x,y"
                                        duration: Appearance.animations.durations.small
                                    }
                                    NAnim {
                                        properties: "opacity,scale"
                                        to: 1
                                        duration: Appearance.animations.durations.small
                                    }
                                }

                                addDisplaced: Transition {
                                    NAnim {
                                        properties: "opacity,scale"
                                        to: 1
                                        duration: Appearance.animations.durations.small
                                    }
                                }

                                displaced: Transition {
                                    NAnim {
                                        properties: "opacity,scale"
                                        to: 1
                                        duration: Appearance.animations.durations.small
                                    }
                                }

                                delegate: ClipboardItemDelegate {
                                    required property var modelData

                                    visible: index < Configs.clipboard.maxEntries

                                    entryId: modelData.entryId
                                    type: modelData.type
                                    preview: modelData.preview
                                    timestamp: modelData.timestamp
                                    pinned: modelData.pinned
                                    sourceApp: modelData.sourceApp
                                    fileName: modelData.fileName
                                    isSelected: GridView.isCurrentItem
                                    inVisual: d.visualActive && index >= entryList.visualStart && index <= entryList.visualEnd

                                    width: GridView.view.cellWidth
                                    height: 64

                                    onActivated: ClipboardManager.copyToClipboard(entryId)
                                    onPinToggled: (id, s) => ClipboardManager.pin(id, s)
                                    onRemoveRequested: id => ClipboardManager.remove(id)
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: verticalFlick
                            visible: entryList.count === 0
                            text: searchField.text.length > 0 ? qsTr("No results for ") + searchField.text : qsTr("Clipboard is empty")
                            font.pixelSize: Appearance.fonts.size.medium
                            color: Colours.m3Colors.m3OnSurfaceVariant
                        }

                        // Page Indicator
                        Row {
                            id: pageIndicatorRow

                            anchors.bottom: hbar.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: Appearance.margin.small
                            spacing: 6
                            visible: entryList.totalPages > 1

                            Repeater {
                                model: entryList.totalPages
                                delegate: Rectangle {
                                    required property int index
                                    implicitWidth: entryList.currentPage === index ? 16 : 6
                                    implicitHeight: 6
                                    radius: 3
                                    color: entryList.currentPage === index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OutlineVariant
                                    opacity: entryList.currentPage === index ? 1.0 : 0.5

                                    Behavior on implicitWidth {
                                        NAnim {}
                                    }
                                    Behavior on opacity {
                                        NAnim {}
                                    }
                                }
                            }
                        }

                        ScrollBar {
                            id: hbar

                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            orientation: Qt.Horizontal
                            policy: ScrollBar.AsNeeded
                        }
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

                            ClipboardPreview {
                                Layout.preferredWidth: d.previewWidth
                                Layout.fillHeight: true
                                entryId: clipboardLayout.currentId

                                onCopyRequested: id => ClipboardManager.copyToClipboard(id)
                                onPinToggled: (id, pinned) => ClipboardManager.pin(id, pinned)
                            }
                        }
                    }
                }
            }
        }
    }
}
// Scope {
//     Connections {
//         target: Configs.clipboard
//         function onEnabledChanged() {
//             ClipboardManager.enabled = Configs.clipboard.enabled;
//         }
//     }
//
//     LazyLoader {
//         activeAsync: GlobalStates.isClipboardOpen
//         component: PanelWindow {
//             id: window
//
//             anchors {
//                 top: true
//                 right: true
//                 left: true
//                 bottom: true
//             }
//
//             color: "transparent"
//             exclusionMode: ExclusionMode.Ignore
//             WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
//             WlrLayershell.namespace: "shell:clipboard"
//             WlrLayershell.layer: WlrLayer.Overlay
//
//             mask: Region {
//                 item: root
//             }
//
//             HyprlandWindow.visibleMask: Region { // qmllint disable
//                 item: root // qmllint disable
//             }
//         }
//     }
// }
