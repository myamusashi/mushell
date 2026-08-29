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
    activeAsync: GlobalStates.isDragAndDropActive || DragAndDropServices.closing
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
        WlrLayershell.namespace: "shell:dragAndDrop"
        WlrLayershell.layer: WlrLayer.Overlay

        mask: Region {
            item: islandBox
        }

        HyprlandWindow.visibleMask: Region { // qmllint disable
            item: islandBox // qmllint disable
        }

        Binding {
            target: DragAndDropServices
            property: "stackLayout"
            value: stackLayout
            when: stackLayout !== null
        }

        Component.onCompleted: {
            DragAndDropServices.islandBox = islandBox;
            DragAndDropServices.stackLayout = stackLayout;

            Qt.callLater(DragAndDropServices.updateContentSize);
        }

        Component.onDestruction: {
            if (DragAndDropServices.stackLayout === stackLayout)
                DragAndDropServices.stackLayout = null;
        }

        Connections {
            target: DragAndDropServices

            function onCurrentStateChanged() {
                Qt.callLater(DragAndDropServices.updateContentSize);
            }
        }

        Item {
            id: islandHost

            y: DragAndDropServices.slidingUp ? (-DragAndDropServices.dotSize - Configs.generals.outerBorderSize) : (Configs.generals.outerBorderSize + Configs.bar.barHeight)
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: islandBox.contentWidth
            implicitHeight: islandBox.contentHeight

            Behavior on y {
                NAnim {
                    duration: DragAndDropServices.slideDuration
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            DropArea {
                id: dropArea

                anchors.fill: parent

                onEntered: drag => {
                    if (drag.hasUrls && (DragAndDropServices.currentState === DragAndDropServices.State.Idle || DragAndDropServices.currentState === DragAndDropServices.State.FilesDropped))
                        DragAndDropServices.currentState = DragAndDropServices.State.Dragging;
                }
                onExited: {
                    if (DragAndDropServices.currentState === DragAndDropServices.State.Dragging)
                        DragAndDropServices.currentState = DragAndDropServices.droppedFiles.length > 0 ? DragAndDropServices.State.FilesDropped : DragAndDropServices.State.Idle;
                }
                onPositionChanged: drag => {
                    if (!drag.hasUrls && DragAndDropServices.currentState === DragAndDropServices.State.Dragging)
                        DragAndDropServices.currentState = DragAndDropServices.droppedFiles.length > 0 ? DragAndDropServices.State.FilesDropped : DragAndDropServices.State.Idle;
                }
                onDropped: drop => {
                    if (DragAndDropServices.currentState !== DragAndDropServices.State.Dragging)
                        return;
                    var incoming = [];
                    for (var i = 0; i < drop.urls.length; i++)
                        incoming.push(String(drop.urls[i]).replace("file://", ""));
                    DragAndDropServices.droppedFiles = DragAndDropServices.droppedFiles.concat(incoming);
                    DragAndDropServices.currentState = DragAndDropServices.State.FilesDropped;
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

                opacity: DragAndDropServices.slidingUp ? 0 : (DragAndDropServices.islandVisible ? 1 : 0)

                radius: DragAndDropServices.currentState > DragAndDropServices.State.Dragging ? Appearance.rounding.normal : Appearance.rounding.full
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
                        switch (DragAndDropServices.currentState) {
                        case DragAndDropServices.State.Dragging:
                            return 1;
                        case DragAndDropServices.State.FilesDropped:
                            return 2;
                        case DragAndDropServices.State.SelectingDevice:
                            return 3;
                        case DragAndDropServices.State.ConfirmDevice:
                            return 4;
                        case DragAndDropServices.State.Transferring:
                            return 5;
                        case DragAndDropServices.State.Completed:
                            return 6;
                        default:
                            return 0;
                        }
                    }

                    onCurrentIndexChanged: Qt.callLater(DragAndDropServices.updateContentSize)

                    Item {
                        implicitWidth: DragAndDropServices.dotSize
                        implicitHeight: DragAndDropServices.dotSize

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: width / 2
                            color: Colours.m3Colors.m3Green
                        }
                    }

                    DraggingContent {
                        active: DragAndDropServices.isDragging
                        onImplicitWidthChanged: {
                            if (DragAndDropServices.isDragging)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDropServices.isDragging)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                    }
                    FilesDroppedContent {
                        island: DragAndDropServices
                        active: DragAndDropServices.isFilesDropped
                        onImplicitWidthChanged: {
                            if (DragAndDropServices.isFilesDropped)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDropServices.isFilesDropped)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                    }
                    DeviceListContent {
                        island: DragAndDropServices
                        active: DragAndDropServices.isSelectingDevice
                        onImplicitWidthChanged: {
                            if (DragAndDropServices.isSelectingDevice)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDropServices.isSelectingDevice)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                    }
                    ConfirmDeviceContent {
                        island: DragAndDropServices
                        active: DragAndDropServices.isConfirmDevice
                        onImplicitWidthChanged: {
                            if (DragAndDropServices.isConfirmDevice)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDropServices.isConfirmDevice)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                    }
                    ProgressContent {
                        island: DragAndDropServices
                        active: DragAndDropServices.isTransferring
                        onImplicitWidthChanged: {
                            if (DragAndDropServices.isTransferring)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDropServices.isTransferring)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                    }
                    DoneContent {
                        island: DragAndDropServices
                        active: DragAndDropServices.isCompleted
                        onImplicitWidthChanged: {
                            if (DragAndDropServices.isCompleted)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                        onImplicitHeightChanged: {
                            if (DragAndDropServices.isCompleted)
                                Qt.callLater(DragAndDropServices.updateContentSize);
                        }
                    }
                }
            }
        }
    }
}
