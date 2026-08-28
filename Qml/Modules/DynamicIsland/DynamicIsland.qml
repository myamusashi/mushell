pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

LazyLoader {
    activeAsync: GlobalStates.isDragAndDropActive || DragAndDrop.closing
    component: PanelWindow {
        id: targetWindow

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

        Binding {
            target: DragAndDrop
            property: "stackLayout"
            value: stackLayout
            when: stackLayout !== null
        }

        Component.onCompleted: {
            DragAndDrop.islandBox = islandBox;
            DragAndDrop.stackLayout = stackLayout;

            Qt.callLater(DragAndDrop.updateContentSize);
        }

        Component.onDestruction: {
            if (DragAndDrop.stackLayout === stackLayout)
                DragAndDrop.stackLayout = null;
        }

        Connections {
            target: DragAndDrop

            function onCurrentStateChanged() {
                Qt.callLater(DragAndDrop.updateContentSize);
            }
        }

        Item {
            id: islandHost

            y: DragAndDrop.slidingUp ? (-DragAndDrop.dotSize - Configs.generals.outerBorderSize) : (Configs.generals.outerBorderSize + Configs.bar.barHeight)
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: islandBox.contentWidth
            implicitHeight: islandBox.contentHeight

            Behavior on y {
                NAnim {
                    duration: DragAndDrop.slideDuration
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            DropArea {
                id: dropArea

                anchors.fill: parent

                onEntered: drag => {
                    if (drag.hasUrls && (DragAndDrop.currentState === DragAndDrop.State.Idle || DragAndDrop.currentState === DragAndDrop.State.FilesDropped))
                        DragAndDrop.currentState = DragAndDrop.State.Dragging;
                }
                onExited: {
                    if (DragAndDrop.currentState === DragAndDrop.State.Dragging)
                        DragAndDrop.currentState = DragAndDrop.droppedFiles.length > 0 ? DragAndDrop.State.FilesDropped : DragAndDrop.State.Idle;
                }
                onPositionChanged: drag => {
                    if (!drag.hasUrls && DragAndDrop.currentState === DragAndDrop.State.Dragging)
                        DragAndDrop.currentState = DragAndDrop.droppedFiles.length > 0 ? DragAndDrop.State.FilesDropped : DragAndDrop.State.Idle;
                }
                onDropped: drop => {
                    if (DragAndDrop.currentState !== DragAndDrop.State.Dragging)
                        return;
                    var incoming = [];
                    for (var i = 0; i < drop.urls.length; i++)
                        incoming.push(String(drop.urls[i]).replace("file://", ""));
                    DragAndDrop.droppedFiles = DragAndDrop.droppedFiles.concat(incoming);
                    DragAndDrop.currentState = DragAndDrop.State.FilesDropped;
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

                opacity: DragAndDrop.slidingUp ? 0 : (DragAndDrop.islandVisible ? 1 : 0)

                radius: DragAndDrop.currentState > DragAndDrop.State.Dragging ? Appearance.rounding.normal : Appearance.rounding.full
                color: GlobalStates.drawerColors
                clip: true

                Behavior on implicitWidth {
                    SpringAnimation {
                        spring: 3
                        damping: 0.3
                        mass: 1
                    }
                }
                Behavior on implicitHeight {
                    SpringAnimation {
                        spring: 3
                        damping: 0.3
                        mass: 1
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
                        switch (DragAndDrop.currentState) {
                        case DragAndDrop.State.Dragging:
                            return 1;
                        case DragAndDrop.State.FilesDropped:
                            return 2;
                        case DragAndDrop.State.SelectingDevice:
                            return 3;
                        case DragAndDrop.State.ConfirmDevice:
                            return 4;
                        case DragAndDrop.State.Transferring:
                            return 5;
                        case DragAndDrop.State.Completed:
                            return 6;
                        default:
                            return 0;
                        }
                    }

                    onCurrentIndexChanged: Qt.callLater(DragAndDrop.updateContentSize)

                    Item {
                        implicitWidth: DragAndDrop.dotSize
                        implicitHeight: DragAndDrop.dotSize

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: width / 2
                            color: Colours.m3Colors.m3Green
                        }
                    }

                    DraggingContent {
                        active: DragAndDrop.isDragging
                        onImplicitWidthChanged: {
                            if (DragAndDrop.isDragging)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDrop.isDragging)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                    }
                    FilesDroppedContent {
                        island: DragAndDrop
                        active: DragAndDrop.isFilesDropped
                        onImplicitWidthChanged: {
                            if (DragAndDrop.isFilesDropped)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDrop.isFilesDropped)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                    }
                    DeviceListContent {
                        island: DragAndDrop
                        active: DragAndDrop.isSelectingDevice
                        onImplicitWidthChanged: {
                            if (DragAndDrop.isSelectingDevice)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDrop.isSelectingDevice)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                    }
                    ConfirmDeviceContent {
                        island: DragAndDrop
                        active: DragAndDrop.isConfirmDevice
                        onImplicitWidthChanged: {
                            if (DragAndDrop.isConfirmDevice)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDrop.isConfirmDevice)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                    }
                    ProgressContent {
                        island: DragAndDrop
                        active: DragAndDrop.isTransferring
                        onImplicitWidthChanged: {
                            if (DragAndDrop.isTransferring)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDrop.isTransferring)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                    }
                    DoneContent {
                        island: DragAndDrop
                        active: DragAndDrop.isCompleted
                        onImplicitWidthChanged: {
                            if (DragAndDrop.isCompleted)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDrop.isCompleted)
                                Qt.callLater(DragAndDrop.updateContentSize);
                        }
                    }
                }
            }
        }
    }
}
