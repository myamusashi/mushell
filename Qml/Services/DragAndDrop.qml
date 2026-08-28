pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.Core.Configs
import qs.Core.States
import qs.Services

Singleton {
    id: root

    enum State {
        Idle,
        Dragging,
        FilesDropped,
        SelectingDevice,
        ConfirmDevice,
        Transferring,
        Completed
    }

    property Item islandBox: null
    property StackLayout stackLayout: null

    property int currentState: DragAndDrop.State.Idle
    property var droppedFiles: []
    property var selectedDevice: null
    property bool transferSuccess: false

    readonly property bool islandVisible: closing || currentState !== DragAndDrop.State.Idle
    readonly property real dotSize: 24
    readonly property int slideDuration: 300
    property bool closing: false
    property bool slidingUp: false
    readonly property bool isDragging: currentState === DragAndDrop.State.Dragging
    readonly property bool isFilesDropped: currentState === DragAndDrop.State.FilesDropped
    readonly property bool isSelectingDevice: currentState === DragAndDrop.State.SelectingDevice
    readonly property bool isConfirmDevice: currentState === DragAndDrop.State.ConfirmDevice
    readonly property bool isTransferring: currentState === DragAndDrop.State.Transferring
    readonly property bool isCompleted: currentState === DragAndDrop.State.Completed

    function acceptDroppedFiles(files) {
        if (!files || files.length === 0)
            return;
        if (currentState !== DragAndDrop.State.Idle && currentState !== DragAndDrop.State.FilesDropped)
            return;
        droppedFiles = droppedFiles.concat(files);
        currentState = DragAndDrop.State.FilesDropped;
    }

    function startTransfer() {
        currentState = DragAndDrop.State.Transferring;
        for (var i = 0; i < droppedFiles.length; i++)
            KDEConnect.shareFile(selectedDevice.id, droppedFiles[i]);
        transferTimer.start();
    }

    function cancelTransfer() {
        transferTimer.stop();
        transferSuccess = false;
        currentState = DragAndDrop.State.Completed;
        resetTimer.start();
    }

    function dismiss() {
        droppedFiles = [];
        selectedDevice = null;
        transferSuccess = false;
        beginClose();
    }

    function beginClose() {
        if (closing)
            return;
        closing = true;
        slidingUp = false;
        droppedFiles = [];
        selectedDevice = null;
        transferSuccess = false;
        currentState = DragAndDrop.State.Idle;
        contractTimer.start();
        slideTimer.start();
    }

    function finishClose() {
        closing = false;
        slidingUp = false;
        droppedFiles = [];
        selectedDevice = null;
        transferSuccess = false;
        currentState = DragAndDrop.State.Idle;
        if (GlobalStates.isDragAndDropActive)
            GlobalStates.setDragAndDropActive(false);
    }

    function goBack() {
        if (currentState === DragAndDrop.State.SelectingDevice || currentState === DragAndDrop.State.ConfirmDevice)
            currentState = DragAndDrop.State.FilesDropped;
    }

    function goToDeviceSelection() {
        currentState = DragAndDrop.State.SelectingDevice;
    }

    function goToConfirmation() {
        currentState = DragAndDrop.State.ConfirmDevice;
    }

    function updateContentSize() {
        if (root.currentState === DragAndDrop.State.Idle) {
            islandBox.contentWidth = root.dotSize;
            islandBox.contentHeight = root.dotSize;
            return;
        }
        var children = stackLayout?.children;
        var index = stackLayout?.currentIndex;
        if (index >= 0 && index < children.length) {
            var child = children[index];
            islandBox.contentWidth = Math.max(120, child.implicitWidth + 24);
            islandBox.contentHeight = Math.max(44, child.implicitHeight + 16);
        }
    }

    Timer {
        id: transferTimer

        interval: Math.min(root.droppedFiles.length * 2000, 15000)
        onTriggered: {
            root.transferSuccess = true;
            root.currentState = DragAndDrop.State.Completed;
            resetTimer.start();
        }
    }

    Timer {
        id: resetTimer

        interval: 3000
        onTriggered: root.dismiss()
    }

    Timer {
        id: contractTimer

        interval: Appearance.animations.durations.expressiveDefaultSpatial
        onTriggered: root.slidingUp = true
    }

    Timer {
        id: slideTimer

        interval: Appearance.animations.durations.expressiveDefaultSpatial + root.slideDuration
        onTriggered: root.finishClose()
    }

    Connections {
        target: GlobalStates

        function onPendingShareFilesChanged() {
            if (GlobalStates.pendingShareFiles.length === 0)
                return;
            root.acceptDroppedFiles(GlobalStates.pendingShareFiles);
            GlobalStates.pendingShareFiles = [];
        }
        function onIsDragAndDropActiveChanged() {
            if (GlobalStates.isDragAndDropActive)
                return;
            transferTimer.stop();
            resetTimer.stop();
            root.beginClose();
        }
    }

    GlobalShortcut { // qmllint disable
        name: "dragAndDrop"
        onPressed: GlobalStates.setDragAndDropActive(!GlobalStates.isDragAndDropActive)
    }

    IpcHandler {
        target: "dragAndDrop"

        function start(): void {
            GlobalStates.setDragAndDropActive(true);
        }
        function stop(): void {
            GlobalStates.setDragAndDropActive(false);
        }
        function toggle(): void {
            GlobalStates.setDragAndDropActive(!GlobalStates.isDragAndDropActive);
        }
        function status(): bool {
            return GlobalStates.isDragAndDropActive;
        }
    }

    Connections {
        target: root
        function onCurrentStateChanged() {
            Qt.callLater(root.updateContentSize);
        }
    }
}
