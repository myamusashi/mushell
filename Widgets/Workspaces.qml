pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

StyledRect {
    id: root

    property real workspaceWidth: (Hypr.focusedMonitor.width - (root.reserved[0] + root.reserved[2])) * scaleFactor / Hypr.focusedMonitor.scale
    property real workspaceHeight: (Hypr.focusedMonitor.height - (root.reserved[1] + root.reserved[3])) * scaleFactor / Hypr.focusedMonitor.scale
    property real containerWidth: workspaceWidth + borderWidth
    property real containerHeight: workspaceHeight + borderWidth
    property list<int> reserved: Hypr.focusedMonitor.lastIpcObject.reserved
	property real scaleFactor: 0.1
	property real borderWidth: 2

    implicitWidth: workspaceRow.width + 20
    implicitHeight: 40

    MArea {
        id: workspaceMBarArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: () => {
            Quickshell.execDetached({
                command: ["sh", "-c", "hyprctl dispatch global quickshell:overview"]
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

                width: 50
                height: 30
                color: workspace?.focused ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OnPrimary
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

                        captureSource: null
                        live: false

                        width: 30 + root.scaleFactor
                        height: 25 + root.scaleFactor
                        scale: (Drag.active && !toplevelData?.floating) ? 0.98 : 1

                        Rectangle {
                            anchors.fill: toplevel
                            color: Themes.m3Colors.m3Outline
                        }

                        x: (toplevelData?.at[0] - (waylandHandle?.fullscreen ? 0 : root.reserved[0])) * root.scaleFactor + 3
                        y: (toplevelData?.at[1] - (waylandHandle?.fullscreen ? 0 : root.reserved[1])) * root.scaleFactor + 3
                        z: (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 2 : toplevelData?.floating ? 1 : 0

                        Drag.active: mouseArea.drag.active
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2
                        Drag.onActiveChanged: {
                            if (Drag.active) {
                                parent = visualParent;
                            } else {
                                var mapped = mapToItem(originalParent, 0, 0);
                                parent = originalParent;

                                if (toplevelData?.floating) {
                                    x = mapped.x;
                                    y = mapped.y;
                                } else if (!isCaught) {
                                    x = mapped.x;
                                    y = mapped.y;
                                } else {
                                    // Fixed repositioning logic
                                    const baseX = toplevelData?.at[0] ?? 0;
                                    const baseY = toplevelData?.at[1] ?? 0;
                                    const offsetX = (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 0 : root.reserved[0];
                                    const offsetY = (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 0 : root.reserved[1];
                                    x = (baseX - offsetX) * root.scaleFactor + 5;
                                    y = (baseY - offsetY) * root.scaleFactor + 5;
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
                                    const x = Math.round((mapped.x - 5) / root.scaleFactor + root.reserved[0]);
                                    const y = Math.round((mapped.y - 5) / root.scaleFactor + root.reserved[1]);

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
