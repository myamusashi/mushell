pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

import "."

Item {
    id: root

    anchors {
        top: bar.bottom
        horizontalCenter: bar.horizontalCenter
    }

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

    implicitWidth: bar.width * 0.35
    implicitHeight: root.islandVisible ? island.contentHeight + Configs.bar.barHeight + 40 : Configs.bar.barHeight + 60

    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name

    readonly property bool islandVisible: root.currentState !== DynamicIsland.State.Idle
    readonly property bool isDragging: root.currentState === DynamicIsland.State.Dragging
    readonly property bool isFilesDropped: root.currentState === DynamicIsland.State.FilesDropped
    readonly property bool isSelectingDevice: root.currentState === DynamicIsland.State.SelectingDevice
    readonly property bool isConfirmDevice: root.currentState === DynamicIsland.State.ConfirmDevice
    readonly property bool isTransferring: root.currentState === DynamicIsland.State.Transferring
    readonly property bool isCompleted: root.currentState === DynamicIsland.State.Completed

    function startTransfer() {
        root.currentState = DynamicIsland.State.Transferring;
        for (var i = 0; i < root.droppedFiles.length; i++)
            KDEConnect.shareFile(root.selectedDevice.id, root.droppedFiles[i]);
        transferTimer.start();
    }

    function cancelTransfer() {
        transferTimer.stop();
        root.transferSuccess = false;
        root.currentState = DynamicIsland.State.Completed;
        resetTimer.start();
    }

    function dismiss() {
        root.currentState = DynamicIsland.State.Idle;
        root.droppedFiles = [];
        root.selectedDevice = null;
        root.transferSuccess = false;
    }

    function goBack() {
        if (root.currentState === DynamicIsland.State.SelectingDevice || root.currentState === DynamicIsland.State.ConfirmDevice)
            root.currentState = DynamicIsland.State.FilesDropped;
    }

    function goToDeviceSelection() {
        root.currentState = DynamicIsland.State.SelectingDevice;
    }

    function goToConfirmation() {
        root.currentState = DynamicIsland.State.ConfirmDevice;
    }

    function updateContentSize() {
        var children = stackLayout.children;
        var index = stackLayout.currentIndex;
        if (index >= 0 && index < children.length) {
            var child = children[index];
            island.contentWidth = Math.max(120, child.implicitWidth + 24);
            island.contentHeight = Math.max(44, child.implicitHeight + 16);
        }
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
        id: island

        anchors {
            top: parent.top
            topMargin: Configs.bar.barHeight
            horizontalCenter: parent.horizontalCenter
        }

        property real contentWidth: 0
        property real contentHeight: 44

        implicitWidth: island.contentWidth
        implicitHeight: island.contentHeight

        opacity: root.islandVisible ? 1 : 0

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

            implicitWidth: island.contentWidth
            implicitHeight: island.contentHeight
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

            onCurrentIndexChanged: Qt.callLater(root.updateContentSize)

            Item {
                implicitWidth: 0
                implicitHeight: 0
            }

            DraggingContent {
                active: root.isDragging
                onImplicitWidthChanged: {
                    if (root.isDragging)
                        Qt.callLater(root.updateContentSize);
                }
                onImplicitHeightChanged: {
                    if (root.isDragging)
                        Qt.callLater(root.updateContentSize);
                }
            }
            FilesDroppedContent {
                island: root
                active: root.isFilesDropped
                onImplicitWidthChanged: {
                    if (root.isFilesDropped)
                        Qt.callLater(root.updateContentSize);
                }
                onImplicitHeightChanged: {
                    if (root.isFilesDropped)
                        Qt.callLater(root.updateContentSize);
                }
            }
            DeviceListContent {
                island: root
                active: root.isSelectingDevice
                onImplicitWidthChanged: {
                    if (root.isSelectingDevice)
                        Qt.callLater(root.updateContentSize);
                }
                onImplicitHeightChanged: {
                    if (root.isSelectingDevice)
                        Qt.callLater(root.updateContentSize);
                }
            }
            ConfirmDeviceContent {
                island: root
                active: root.isConfirmDevice
                onImplicitWidthChanged: {
                    if (root.isConfirmDevice)
                        Qt.callLater(root.updateContentSize);
                }
                onImplicitHeightChanged: {
                    if (root.isConfirmDevice)
                        Qt.callLater(root.updateContentSize);
                }
            }
            ProgressContent {
                island: root
                active: root.isTransferring
                onImplicitWidthChanged: {
                    if (root.isTransferring)
                        Qt.callLater(root.updateContentSize);
                }
                onImplicitHeightChanged: {
                    if (root.isTransferring)
                        Qt.callLater(root.updateContentSize);
                }
            }
            DoneContent {
                island: root
                active: root.isCompleted
                onImplicitWidthChanged: {
                    if (root.isCompleted)
                        Qt.callLater(root.updateContentSize);
                }
                onImplicitHeightChanged: {
                    if (root.isCompleted)
                        Qt.callLater(root.updateContentSize);
                }
            }
        }
    }
}
