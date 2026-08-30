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

    property int currentState: DragAndDropServices.State.Idle
    property var droppedFiles: []
    property var selectedDevice: null
    property bool transferSuccess: false
    property bool slidingUp: false

    readonly property bool isArmed: GlobalStates.isDragAndDropActive // qmllint disable
    readonly property bool islandVisible: isArmed || closing || currentState !== DragAndDropServices.State.Idle
    readonly property real dotSize: 24
    readonly property int slideDuration: 300
    property bool closing: false
    readonly property bool isDragging: currentState === DragAndDropServices.State.Dragging
    readonly property bool isFilesDropped: currentState === DragAndDropServices.State.FilesDropped
    readonly property bool isSelectingDevice: currentState === DragAndDropServices.State.SelectingDevice
    readonly property bool isConfirmDevice: currentState === DragAndDropServices.State.ConfirmDevice
    readonly property bool isTransferring: currentState === DragAndDropServices.State.Transferring
    readonly property bool isCompleted: currentState === DragAndDropServices.State.Completed

    function acceptDroppedFiles(files) {
        if (!files || files.length === 0)
            return;
        if (currentState !== DragAndDropServices.State.Idle && currentState !== DragAndDropServices.State.FilesDropped)
            return;
        droppedFiles = droppedFiles.concat(files);
        currentState = DragAndDropServices.State.FilesDropped;
    }

    function startTransfer() {
        currentState = DragAndDropServices.State.Transferring;
        for (var i = 0; i < droppedFiles.length; i++)
            KDEConnect.shareFile(selectedDevice.id, droppedFiles[i]);
        transferTimer.start();
    }

    function cancelTransfer() {
        transferTimer.stop();
        transferSuccess = false;
        currentState = DragAndDropServices.State.Completed;
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
        currentState = DragAndDropServices.State.Idle;
        contractTimer.start();
        slideTimer.start();
    }

    function finishClose() {
        const wasActive = GlobalStates.isDragAndDropActive;
        droppedFiles = [];
        selectedDevice = null;
        transferSuccess = false;
        currentState = DragAndDropServices.State.Idle;
        if (wasActive)
            GlobalStates.setDragAndDropActive(false);
        closing = false;
        slidingUp = false;
    }

    function goBack() {
        if (currentState === DragAndDropServices.State.SelectingDevice || currentState === DragAndDropServices.State.ConfirmDevice)
            currentState = DragAndDropServices.State.FilesDropped;
    }

    function goToDeviceSelection() {
        currentState = DragAndDropServices.State.SelectingDevice;
    }

    function goToConfirmation() {
        currentState = DragAndDropServices.State.ConfirmDevice;
    }

    function updateContentSize() {
        if (currentState === DragAndDropServices.State.Idle) {
            islandBox.contentWidth = dotSize;
            islandBox.contentHeight = dotSize;
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
            root.currentState = DragAndDropServices.State.Completed;
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
            if (GlobalStates.isDragAndDropActive) {
                if (root.closing) {
                    contractTimer.stop();
                    slideTimer.stop();
                    root.closing = false;
                    root.slidingUp = false;
                }
                return;
            }
            if (root.closing)
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
