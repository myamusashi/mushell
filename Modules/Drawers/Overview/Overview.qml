pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Helpers
import qs.Services
import qs.Components

// Thx M7moud El-zayat for your Overview code
StyledRect {
    id: root

    property bool isOverviewOpen: GlobalStates.isOverviewOpen
    property real scaleFactor: 0.2
    property real borderWidth: 2
    property bool wallpaperEnabled: true
    property real workspaceWidth: {
        if (!Hypr.focusedMonitor || !Hypr.focusedMonitor.scale)
            return 0;
        var reserved0 = reserved[0] || 0;
        var reserved2 = reserved[2] || 0;
        return (Hypr.focusedMonitor.width - (reserved0 + reserved2)) * scaleFactor / Hypr.focusedMonitor.scale;
    }
    property real workspaceHeight: {
        if (!Hypr.focusedMonitor || !Hypr.focusedMonitor.scale)
            return 0;
        var reserved1 = reserved[1] || 0;
        var reserved3 = reserved[3] || 0;
        return (parent.height - (reserved1 + reserved3)) * scaleFactor / Hypr.focusedMonitor.scale;
    }
    property real containerWidth: workspaceWidth + borderWidth
    property real containerHeight: workspaceHeight + borderWidth
    property list<int> reserved: Hypr.focusedMonitor.lastIpcObject.reserved

    anchors.verticalCenter: parent.verticalCenter
    x: isOverviewOpen ? (parent.width - width) / 2 : -width
    implicitWidth: contentGrid.implicitWidth * 2.5
    implicitHeight: contentGrid.implicitHeight * 2.5
    color: "transparent"

    opacity: isOverviewOpen ? 1 : 0
    visible: opacity > 0

    Behavior on x {
        NAnim {}
    }

    Behavior on opacity {
        NAnim {}
    }

    StyledRect {
        color: GlobalStates.drawerColors
        border.color: Colours.m3Colors.m3Outline
        anchors.fill: contentGrid
        anchors.margins: -12

        opacity: root.isOverviewOpen ? 1 : 0
        scale: root.isOverviewOpen ? 1 : 0.95

        Behavior on opacity {
            NAnim {}
        }

        Behavior on scale {
            NAnim {}
        }
    }

    GlobalShortcut {
        name: "overview"
        onPressed: GlobalStates.isOverviewOpen = !GlobalStates.isOverviewOpen
    }

    StyledRect {
        id: overLayer

        color: "transparent"
        z: 1
        anchors.fill: parent
    }

    GridLayout {
        id: contentGrid

        rows: 2
        columns: 4
        rowSpacing: 12
        columnSpacing: 12
        anchors.centerIn: parent

        opacity: root.isOverviewOpen ? 1 : 0
        scale: root.isOverviewOpen ? 1 : 0.9

        Behavior on opacity {
            NAnim {}
        }

        Behavior on scale {
            NAnim {}
        }

        Repeater {
            model: 8
            delegate: StyledRect {
                id: workspaceContainer

                required property int index
                property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(w => w.id === index + 1) ?? null
                property bool hasFullscreen: !!(workspace?.toplevels?.values.some(t => t.wayland?.fullscreen))
                property bool hasMaximized: !!(workspace?.toplevels?.values.some(t => t.wayland?.maximized))

                implicitWidth: root.containerWidth + 25
                implicitHeight: root.containerHeight + 25
                color: "transparent"
                clip: true
                border.width: 2
                border.color: hasMaximized ? "red" : workspace?.focused ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary

                opacity: root.isOverviewOpen ? 1 : 0
                scale: root.isOverviewOpen ? 1 : 0.85

                Behavior on opacity {
                    NAnim {}
                }

                Behavior on scale {
                    NAnim {}
                }

                FileView {
                    id: wallid

                    path: Qt.resolvedUrl(Paths.currentWallpaperFile)
                    watchChanges: true
                    onFileChanged: reload()
                }

                Loader {
                    active: root.wallpaperEnabled
                    visible: active
                    anchors.centerIn: parent
                    sourceComponent: Image {
                        source: wallid.text().trim()
                        sourceSize: Qt.size(workspaceContainer.width, workspaceContainer.height)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                }

                DropArea {
                    anchors.fill: parent
                    onEntered: drag => drag.source.isCaught = true
                    onExited: drag.source.isCaught = false
                    onDropped: drag => {
                        const toplevel = drag.source;
                        if (toplevel.modelData.workspace !== workspaceContainer.workspace) {
                            const address = toplevel.modelData.address;
                            Hypr.dispatch(`movetoworkspacesilent ${workspaceContainer.index + 1}, address:0x${address}`);
                            Hypr.dispatch(`movewindowpixel exact ${toplevel.initX} ${toplevel.initY}, address:0x${address}`);
                        }
                    }
                }

                MArea {
                    anchors.fill: parent
                    onClicked: {
                        if (workspaceContainer.workspace !== Hyprland.focusedWorkspace)
                            Hypr.dispatch("workspace" + parent.index + 1);
                    }
                }

                Loader {
                    id: loader

                    anchors.fill: parent
                    active: root.isOverviewOpen
                    asynchronous: true
                    sourceComponent: Repeater {
                        model: workspaceContainer.workspace?.toplevels
                        delegate: ScreencopyView {
                            id: toplevel

                            required property HyprlandToplevel modelData
                            property Toplevel waylandHandle: modelData?.wayland
                            property var toplevelData: modelData.lastIpcObject
                            property int initX: toplevelData.at[0] ?? 0
                            property int initY: toplevelData.at[1] ?? 0
                            property StyledRect originalParent: workspaceContainer
                            property StyledRect visualParent: overLayer
                            property bool isCaught: false

                            captureSource: waylandHandle
                            live: true
                            width: sourceSize.width * root.scaleFactor / Hypr.focusedMonitor.scale
                            height: sourceSize.height * root.scaleFactor / Hypr.focusedMonitor.scale
                            scale: (Drag.active && !toplevelData?.floating) ? 0.75 : 1
                            x: (toplevelData?.at[0] - (waylandHandle?.fullscreen ? 0 : root.reserved[0])) * root.scaleFactor + root.borderWidth + 12
                            y: (toplevelData?.at[1] - (waylandHandle?.fullscreen ? 0 : root.reserved[1])) * root.scaleFactor + root.borderWidth + 12
                            z: (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 2 : toplevelData?.floating ? 1 : 0
                            opacity: root.isOverviewOpen ? 1 : 0

                            Behavior on scale {
                                NAnim {}
                            }

                            Behavior on opacity {
                                NAnim {}
                            }

                            Drag.active: mouseArea.drag.active
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2
                            Drag.onActiveChanged: {
                                if (Drag.active)
                                    parent = visualParent;
                                else {
                                    var mapped = mapToItem(originalParent, 0, 0);
                                    parent = originalParent;
                                    if (toplevelData?.floating) {
                                        x = mapped.x;
                                        y = mapped.y;
                                    } else if (!toplevelData?.floating) {
                                        x = !isCaught ? mapped.x : (toplevelData?.at[0] - (waylandHandle?.fullscreen ? 0 : root.reserved[0])) * root.scaleFactor + root.borderWidth + 12;
                                        y = !isCaught ? mapped.y : (toplevelData?.at[1] - (waylandHandle?.fullscreen ? 0 : root.reserved[1])) * root.scaleFactor + root.borderWidth + 12;
                                    }
                                }
                            }

                            IconImage {
                                id: icon

                                anchors.centerIn: parent
                                source: Quickshell.iconPath(DesktopEntries.heuristicLookup(toplevel.waylandHandle?.appId)?.icon, "image-missing")
                                asynchronous: true
                                width: 44
                                height: 44
                                backer.cache: true
                                backer.asynchronous: true
                            }

                            MArea {
                                id: mouseArea

                                property bool dragged: false
                                drag.target: (toplevel.waylandHandle?.fullscreen || toplevel.waylandHandle?.maximized) ? undefined : toplevel
                                cursorShape: dragged ? Qt.DragMoveCursor : Qt.ArrowCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                anchors.fill: parent

                                onPressed: dragged = false

                                onPositionChanged: {
                                    if (drag.active)
                                        dragged = true;
                                }

                                onClicked: mouse => {
                                    if (!dragged) {
                                        if (mouse.button === Qt.LeftButton)
                                            toplevel.waylandHandle.activate();
                                        else if (mouse.button === Qt.RightButton)
                                            toplevel.waylandHandle.close();
                                    }
                                }

                                onReleased: {
                                    if (dragged && !(toplevel.waylandHandle?.fullscreen || toplevel.waylandHandle?.maximized)) {
                                        const mapped = toplevel.mapToItem(toplevel.originalParent, 0, 0);
                                        const x = Math.round(mapped.x / root.scaleFactor + root.reserved[0]);
                                        const y = Math.round(mapped.y / root.scaleFactor + root.reserved[1]);
                                        Hypr.dispatch(`movewindowpixel exact ${x} ${y}, address:0x${toplevel.modelData.address}`);
                                        toplevel.Drag.drop();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
