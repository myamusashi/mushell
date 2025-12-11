pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: root

    property real workspaceWidth: Hypr.focusedMonitor.width - (root.reserved[0] + root.reserved[2])
    property real workspaceHeight: Hypr.focusedMonitor.height - (root.reserved[1] + root.reserved[3])
    property real containerWidth: 60
    property real containerHeight: 30
    property list<int> reserved: Hypr.focusedMonitor.lastIpcObject.reserved
    property real scaleFactor: Math.min(containerWidth / workspaceWidth, containerHeight / workspaceHeight)
    property real borderWidth: 2

    implicitWidth: workspaceRow.width
    implicitHeight: 30

    MArea {
        id: workspaceMBarArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: () => {
            Quickshell.execDetached({
                                        "command": ["sh", "-c", "hyprctl dispatch global quickshell:overview"]
                                    });
        }
    }

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Repeater {
            model: Workspaces.maxWorkspace + 1

            delegate: StyledRect {
                id: workspaceContainer

                width: root.containerWidth
                height: root.containerHeight
                color: workspace?.focused ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                radius: 0
                clip: true
                required property int index
                property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(w => w.id === index + 1) ?? null
                property bool hasFullscreen: !!(workspace?.toplevels?.values.some(t => t.wayland?.fullscreen))
                property bool hasMaximized: !!(workspace?.toplevels?.values.some(t => t.wayland?.maximized))

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
                        Hypr.dispatch("workspace " + (parent.index + 1));
                    }
                }

                Repeater {
                    model: workspaceContainer.workspace?.toplevels

                    delegate: ScreencopyView {
                        id: toplevel

                        required property HyprlandToplevel modelData
                        property Toplevel waylandHandle: modelData?.wayland
                        property var toplevelData: modelData.lastIpcObject
                        property int initX: toplevelData.at[0] ?? 0
                        property int initY: toplevelData.at[1] ?? 0
                        property StyledRect originalParent: workspaceContainer
                        property StyledRect visualParent: root
                        property bool isCaught: false

                        captureSource: waylandHandle
                        live: false

                        width: sourceSize.width * root.scaleFactor / Hypr.focusedMonitor.scale
                        height: sourceSize.height * root.scaleFactor / Hypr.focusedMonitor.scale
                        scale: (Drag.active && !toplevelData?.floating) ? 0.98 : 1

                        Rectangle {
                            anchors.fill: parent
                            color: toplevel.modelData.activated ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                            border.color: toplevel.modelData.activated ? Colours.m3Colors.m3Outline : Colours.m3Colors.m3OutlineVariant
                            border.width: 1
                        }

                        x: (toplevelData?.at[0] - (waylandHandle?.fullscreen ? 0 : root.reserved[0])) * root.scaleFactor + (root.containerWidth - root.workspaceWidth * root.scaleFactor) / 2
                        y: (toplevelData?.at[1] - (waylandHandle?.fullscreen ? 0 : root.reserved[1])) * root.scaleFactor + (root.containerHeight - root.workspaceHeight * root.scaleFactor) / 2
                        z: (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 2 : toplevelData?.floating ? 1 : 0

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
                                } else if (!isCaught) {
                                    x = mapped.x;
                                    y = mapped.y;
                                } else {
                                    const baseX = toplevelData?.at[0] ?? 0;
                                    const baseY = toplevelData?.at[1] ?? 0;
                                    const offsetX = (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 0 : root.reserved[0];
                                    const offsetY = (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 0 : root.reserved[1];
                                    x = (baseX - offsetX) * root.scaleFactor + (root.containerWidth - root.workspaceWidth * root.scaleFactor) / 2;
                                    y = (baseY - offsetY) * root.scaleFactor + (root.containerHeight - root.workspaceHeight * root.scaleFactor) / 2;
                                }
                            }
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
                                    const centerOffsetX = (root.containerWidth - root.workspaceWidth * root.scaleFactor) / 2;
                                    const centerOffsetY = (root.containerHeight - root.workspaceHeight * root.scaleFactor) / 2;
                                    const x = Math.round((mapped.x - centerOffsetX) / root.scaleFactor + root.reserved[0]);
                                    const y = Math.round((mapped.y - centerOffsetY) / root.scaleFactor + root.reserved[1]);

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
