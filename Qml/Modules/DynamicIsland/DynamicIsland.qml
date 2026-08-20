pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Scope {
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

    property int currentState: DynamicIsland.State.Idle
    property var droppedFiles: []
    property var selectedDevice: null
    property bool transferSuccess: false

    readonly property bool islandVisible: isArmed || closing || currentState !== DynamicIsland.State.Idle
    readonly property bool isArmed: GlobalStates.isDynamicIslandActive
    readonly property real dotSize: 24
    readonly property int slideDuration: 300
    property bool closing: false
    property bool slidingUp: false
    readonly property bool isDragging: currentState === DynamicIsland.State.Dragging
    readonly property bool isFilesDropped: currentState === DynamicIsland.State.FilesDropped
    readonly property bool isSelectingDevice: currentState === DynamicIsland.State.SelectingDevice
    readonly property bool isConfirmDevice: currentState === DynamicIsland.State.ConfirmDevice
    readonly property bool isTransferring: currentState === DynamicIsland.State.Transferring
    readonly property bool isCompleted: currentState === DynamicIsland.State.Completed

    function startTransfer() {
        currentState = DynamicIsland.State.Transferring;
        for (var i = 0; i < droppedFiles.length; i++)
            KDEConnect.shareFile(selectedDevice.id, droppedFiles[i]);
        transferTimer.start();
    }

    function cancelTransfer() {
        transferTimer.stop();
        transferSuccess = false;
        currentState = DynamicIsland.State.Completed;
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
        currentState = DynamicIsland.State.Idle;
        contractTimer.start();
        slideTimer.start();
    }

    function finishClose() {
        closing = false;
        slidingUp = false;
        droppedFiles = [];
        selectedDevice = null;
        transferSuccess = false;
        currentState = DynamicIsland.State.Idle;
        if (GlobalStates.isDynamicIslandActive)
            GlobalStates.setDynamicIslandActive(false);
    }

    function goBack() {
        if (currentState === DynamicIsland.State.SelectingDevice || currentState === DynamicIsland.State.ConfirmDevice)
            currentState = DynamicIsland.State.FilesDropped;
    }

    function goToDeviceSelection() {
        currentState = DynamicIsland.State.SelectingDevice;
    }

    function goToConfirmation() {
        currentState = DynamicIsland.State.ConfirmDevice;
    }

    Timer {
        id: transferTimer

        interval: Math.min(root.droppedFiles.length * 2000, 15000)
        onTriggered: {
            root.transferSuccess = true;
            root.currentState = DynamicIsland.State.Completed;
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
        function onIsDynamicIslandActiveChanged() {
            if (GlobalStates.isDynamicIslandActive)
                return;
            transferTimer.stop();
            resetTimer.stop();
            root.beginClose();
        }
    }

    // qmllint disable
    GlobalShortcut {
        name: "dynamicIsland"
        onPressed: root.setDynamicIslandActive(!root.isDynamicIslandActive)
    }
    // qmllint enable

    IpcHandler {
        target: "dynamicIsland"

        function start(): void {
            GlobalStates.setDynamicIslandActive(true);
        }
        function stop(): void {
            GlobalStates.setDynamicIslandActive(false);
        }
        function toggle(): void {
            GlobalStates.setDynamicIslandActive(!GlobalStates.isDynamicIslandActive);
        }
        function status(): bool {
            return GlobalStates.isDynamicIslandActive;
        }
    }

    LazyLoader {
        activeAsync: GlobalStates.isDynamicIslandActive || root.closing
        component: PanelWindow {
            id: win

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "shell:dynamicIsland"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region {
                item: islandBox
            }

            HyprlandWindow.visibleMask: Region { // qmllint disable
                item: islandBox // qmllint disable
            }

            Component.onCompleted: Qt.callLater(updateContentSize)

            function updateContentSize() {
                if (root.currentState === DynamicIsland.State.Idle) {
                    islandBox.contentWidth = root.dotSize;
                    islandBox.contentHeight = root.dotSize;
                    return;
                }
                var children = stackLayout.children;
                var index = stackLayout.currentIndex;
                if (index >= 0 && index < children.length) {
                    var child = children[index];
                    islandBox.contentWidth = Math.max(120, child.implicitWidth + 24);
                    islandBox.contentHeight = Math.max(44, child.implicitHeight + 16);
                }
            }

            Connections {
                target: root
                function onCurrentStateChanged() {
                    Qt.callLater(win.updateContentSize);
                }
            }

            Item {
                id: islandHost

                y: root.slidingUp ? (-root.dotSize - Configs.generals.outerBorderSize) : (Configs.generals.outerBorderSize + Configs.bar.barHeight)
                anchors.horizontalCenter: parent.horizontalCenter

                implicitWidth: islandBox.contentWidth
                implicitHeight: islandBox.contentHeight

                Behavior on y {
                    NAnim {
                        duration: root.slideDuration
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                DropArea {
                    id: dropArea

                    anchors.fill: parent

                    onEntered: drag => {
                        if (drag.hasUrls && (root.currentState === DynamicIsland.State.Idle || root.currentState === DynamicIsland.State.FilesDropped))
                            root.currentState = DynamicIsland.State.Dragging;
                    }
                    onExited: {
                        if (root.currentState === DynamicIsland.State.Dragging)
                            root.currentState = root.droppedFiles.length > 0 ? DynamicIsland.State.FilesDropped : DynamicIsland.State.Idle;
                    }
                    onPositionChanged: drag => {
                        if (!drag.hasUrls && root.currentState === DynamicIsland.State.Dragging)
                            root.currentState = root.droppedFiles.length > 0 ? DynamicIsland.State.FilesDropped : DynamicIsland.State.Idle;
                    }
                    onDropped: drop => {
                        if (root.currentState !== DynamicIsland.State.Dragging)
                            return;
                        var incoming = [];
                        for (var i = 0; i < drop.urls.length; i++)
                            incoming.push(String(drop.urls[i]).replace("file://", ""));
                        root.droppedFiles = root.droppedFiles.concat(incoming);
                        root.currentState = DynamicIsland.State.FilesDropped;
                    }
                }

                WrapperRectangle {
                    id: islandBox

                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }

                    property real contentWidth: 120
                    property real contentHeight: 44

                    implicitWidth: islandBox.contentWidth
                    implicitHeight: islandBox.contentHeight

                    opacity: root.slidingUp ? 0 : (root.islandVisible ? 1 : 0)

                    radius: root.currentState > DynamicIsland.State.Dragging ? Appearance.rounding.normal : Appearance.rounding.full
                    color: GlobalStates.drawerColors
                    clip: true

                    Behavior on implicitWidth {
                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on implicitHeight {
                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on radius {
                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on opacity {
                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }

                    StackLayout {
                        id: stackLayout

                        implicitWidth: islandBox.contentWidth
                        implicitHeight: islandBox.contentHeight
                        currentIndex: {
                            switch (root.currentState) {
                            case DynamicIsland.State.Dragging:
                                return 1;
                            case DynamicIsland.State.FilesDropped:
                                return 2;
                            case DynamicIsland.State.SelectingDevice:
                                return 3;
                            case DynamicIsland.State.ConfirmDevice:
                                return 4;
                            case DynamicIsland.State.Transferring:
                                return 5;
                            case DynamicIsland.State.Completed:
                                return 6;
                            default:
                                return 0;
                            }
                        }

                        onCurrentIndexChanged: Qt.callLater(win.updateContentSize)

                        Item {
                            implicitWidth: root.dotSize
                            implicitHeight: root.dotSize

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 10
                                radius: width / 2
                                color: Colours.m3Colors.m3Green
                            }
                        }

                        DraggingContent {
                            active: root.isDragging
                            onImplicitWidthChanged: {
                                if (root.isDragging)
                                    Qt.callLater(win.updateContentSize);
                            }
                            onImplicitHeightChanged: {
                                if (root.isDragging)
                                    Qt.callLater(win.updateContentSize);
                            }
                        }
                        FilesDroppedContent {
                            island: root
                            active: root.isFilesDropped
                            onImplicitWidthChanged: {
                                if (root.isFilesDropped)
                                    Qt.callLater(win.updateContentSize);
                            }
                            onImplicitHeightChanged: {
                                if (root.isFilesDropped)
                                    Qt.callLater(win.updateContentSize);
                            }
                        }
                        DeviceListContent {
                            island: root
                            active: root.isSelectingDevice
                            onImplicitWidthChanged: {
                                if (root.isSelectingDevice)
                                    Qt.callLater(win.updateContentSize);
                            }
                            onImplicitHeightChanged: {
                                if (root.isSelectingDevice)
                                    Qt.callLater(win.updateContentSize);
                            }
                        }
                        ConfirmDeviceContent {
                            island: root
                            active: root.isConfirmDevice
                            onImplicitWidthChanged: {
                                if (root.isConfirmDevice)
                                    Qt.callLater(win.updateContentSize);
                            }
                            onImplicitHeightChanged: {
                                if (root.isConfirmDevice)
                                    Qt.callLater(win.updateContentSize);
                            }
                        }
                        ProgressContent {
                            island: root
                            active: root.isTransferring
                            onImplicitWidthChanged: {
                                if (root.isTransferring)
                                    Qt.callLater(win.updateContentSize);
                            }
                            onImplicitHeightChanged: {
                                if (root.isTransferring)
                                    Qt.callLater(win.updateContentSize);
                            }
                        }
                        DoneContent {
                            island: root
                            active: root.isCompleted
                            onImplicitWidthChanged: {
                                if (root.isCompleted)
                                    Qt.callLater(win.updateContentSize);
                            }
                            onImplicitHeightChanged: {
                                if (root.isCompleted)
                                    Qt.callLater(win.updateContentSize);
                            }
                        }
                    }
                }
            }
        }
    }
}
