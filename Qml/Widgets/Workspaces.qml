pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "../Components/Base"

StyledRect {
    id: root

    required property ShellScreen monitor

    implicitWidth: Configs.bar.workspacesIndicator === "dot" ? loader.item.implicitWidth : loaderInteractiveWp.item.implicitWidth // qmllint disable
    implicitHeight: 30

    property real workspaceWidth: monitor.width - (reserved[0] + reserved[2])
    property real workspaceHeight: monitor.height - (reserved[1] + reserved[3])
    property real containerWidth: 60
    property real containerHeight: 30
    property var reserved: Hypr.monitors.values.map(m => m.lastIpcObject.reserved)
    property real scaleFactor: Math.min(containerWidth / workspaceWidth, containerHeight / workspaceHeight)
    property real borderWidth: 2

    MArea {
        id: workspaceMBarArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        propagateComposedEvents: true
        onClicked: mouse => {
            let loaderPos = mapToItem(loaderInteractiveWp, mouse.x, mouse.y);
            if (loaderInteractiveWp.contains(Qt.point(loaderPos.x, loaderPos.y))) {
                mouse.accepted = false;
                return;
            }

            Quickshell.execDetached({
                "command": ["sh", "-c", "hyprctl dispatch 'hl.global(\"quickshell:overview\")'"]
            });
        }
    }

    Loader {
        id: loader

        anchors.fill: parent
        active: Configs.bar.workspacesIndicator === "dot"
        sourceComponent: dotWorkspaceIndicator
    }

    Loader {
        id: loaderInteractiveWp

        anchors.fill: parent
        active: Configs.bar.workspacesIndicator !== "dot"
        sourceComponent: interactiveWorkspaceIndicator
    }

    Component {
        id: dotWorkspaceIndicator

        Row {
            id: container

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            // Caelestia credit
            readonly property var occupied: Hypr.workspaces.values.reduce((acc, curr) => {
                acc[curr.id] = curr.lastIpcObject.windows > 0;
                return acc;
            }, {})
            property int focusedWorkspace: Hypr.activeWsId

            clip: true
            spacing: 0
            Repeater {
                model: {
                    const maxOccupied = Object.keys(container.occupied).filter(id => container.occupied[id]).reduce((max, id) => Math.max(max, parseInt(id)), 0);
                    const minFromFocus = container.focusedWorkspace >= Configs.bar.visibleWorkspace ? container.focusedWorkspace : Configs.bar.visibleWorkspace;
                    return Math.max(Configs.bar.visibleWorkspace, minFromFocus, maxOccupied);
                }
                delegate: Item {
                    id: delegateRoot

                    required property int index
                    property int workspaceId: index + 1
                    property bool isActive: container.focusedWorkspace === workspaceId
                    property bool isOccupied: container.occupied[workspaceId] === true
                    property bool isEmpty: !isOccupied && !isActive

                    implicitHeight: parent.height
                    implicitWidth: isActive ? 40 : (height ? height : 1)

                    Behavior on implicitWidth {
                        NAnim {
                            duration: Appearance.animations.durations.emphasized
                            easing.bezierCurve: Appearance.animations.curves.emphasized
                        }
                    }

                    MArea {
                        visible: !delegateRoot.isActive
                        anchors.fill: parent
                        layerColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.8)
                        layerRadius: 5
                        onClicked: Workspaces.switchWorkspace(delegateRoot.workspaceId)
                    }

                    StyledRect {
                        id: fgIndicator

                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                        }
                        implicitWidth: delegateRoot.isActive ? 24 : 8
                        implicitHeight: 8
                        radius: Appearance.rounding.small
                        color: {
                            if (delegateRoot.isActive)
                                return Colours.m3Colors.m3Primary;
                            else if (delegateRoot.isOccupied)
                                return Colours.m3Colors.m3PrimaryFixedDim;
                            else
                                return Colours.m3Colors.m3OutlineVariant;
                        }
                        opacity: delegateRoot.isActive ? 1.0 : 0.5

                        Behavior on implicitWidth {
                            NAnim {
                                duration: Appearance.animations.durations.emphasized
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }
                        Behavior on opacity {
                            NAnim {
                                duration: Appearance.animations.durations.emphasized
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: interactiveWorkspaceIndicator

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

                    property bool hasFullscreen: !!(workspace?.toplevels?.values.some(t => t.wayland?.fullscreen))
                    property bool hasMaximized: !!(workspace?.toplevels?.values.some(t => t.wayland?.maximized))

                    property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(w => w.id === index + 1) ?? null

                    // Use this workspace's own monitor, fall back to focusedMonitor
                    property var wsMonitor: workspace?.monitor ?? Hypr.focusedMonitor
                    property list<int> wsReserved: wsMonitor.lastIpcObject.reserved ?? [0, 0, 0, 0]

                    // Monitor logical origin (physical px ÷ scale = logical px, matches Hyprland's at[] coords)
                    property real monitorLogicalX: wsMonitor.x / wsMonitor.scale
                    property real monitorLogicalY: wsMonitor.y / wsMonitor.scale
                    property real monitorLogicalW: wsMonitor.width / wsMonitor.scale
                    property real monitorLogicalH: wsMonitor.height / wsMonitor.scale

                    // Usable area after reserved struts
                    property real usableW: monitorLogicalW - (wsReserved[0] + wsReserved[2])
                    property real usableH: monitorLogicalH - (wsReserved[1] + wsReserved[3])

                    // Scale to fit the container box
                    property real scaleFactor: Math.min(root.containerWidth / usableW, root.containerHeight / usableH)

                    DropArea {
                        anchors.fill: parent

                        onEntered: drag => drag.source.isCaught = true
                        onExited: drag.source.isCaught = false

                        onDropped: drag => {
                            const toplevel = drag.source;

                            if (toplevel.modelData.workspace !== workspaceContainer.workspace) { // qmllint disable
                                const address = toplevel.modelData.address; // qmllint disable
                                Hypr.dispatch("hl.movetoworkspacesilent(" + (workspaceContainer.index + 1) + ", \"address:0x" + address + "\")");
                                Hypr.dispatch("hl.movewindowpixel(\"exact " + toplevel.initX + " " + toplevel.initY + "\", \"address:0x" + address + "\")"); // qmllint disable
                            }
                        }
                    }

                    MArea {
                        anchors.fill: parent
                        onClicked: {
                            if (workspaceContainer.workspace !== Hyprland.focusedWorkspace)
                                Workspaces.switchWorkspace(parent.index + 1);
                        }
                    }

                    Repeater {
                        model: workspaceContainer.workspace?.toplevels

                        delegate: ScreencopyView {
                            id: toplevel

                            required property HyprlandToplevel modelData
                            property Toplevel waylandHandle: modelData?.wayland // qmllint disable
                            property var toplevelData: modelData.lastIpcObject
                            property int initX: toplevelData.at[0] ?? 0
                            property int initY: toplevelData.at[1] ?? 0
                            property StyledRect originalParent: workspaceContainer
                            property StyledRect visualParent: root
                            property bool isCaught: false

                            // Helpers that centralise the coordinate math
                            // Window at[] coords are in logical global space,
                            // subtract the monitor's logical origin + reserved to get
                            // coords relative to the usable area of this workspace tile.
                            property real localX: {
                                const atX = toplevelData?.at[0] ?? 0;
                                const originX = workspaceContainer.monitorLogicalX;
                                const reserved = waylandHandle?.fullscreen ? 0 : workspaceContainer.wsReserved[0];
                                return atX - originX - reserved;
                            }
                            property real localY: {
                                const atY = toplevelData?.at[1] ?? 0;
                                const originY = workspaceContainer.monitorLogicalY;
                                const reserved = waylandHandle?.fullscreen ? 0 : workspaceContainer.wsReserved[1];
                                return atY - originY - reserved;
                            }

                            // Centering offset so the usable area is centred in the container
                            property real centerOffsetX: (root.containerWidth - workspaceContainer.usableW * workspaceContainer.scaleFactor) / 2
                            property real centerOffsetY: (root.containerHeight - workspaceContainer.usableH * workspaceContainer.scaleFactor) / 2

                            captureSource: waylandHandle
                            live: false

                            width: sourceSize.width * workspaceContainer.scaleFactor / workspaceContainer.wsMonitor.scale
                            height: sourceSize.height * workspaceContainer.scaleFactor / workspaceContainer.wsMonitor.scale
                            scale: (Drag.active && !toplevelData?.floating) ? 0.98 : 1

                            x: localX * workspaceContainer.scaleFactor + centerOffsetX
                            y: localY * workspaceContainer.scaleFactor + centerOffsetY
                            z: (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 2 : toplevelData?.floating ? 1 : 0

                            Rectangle {
                                anchors.fill: parent
                                color: toplevel.modelData.activated ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                                border.color: toplevel.modelData.activated ? Colours.m3Colors.m3Outline : Colours.m3Colors.m3OutlineVariant
                                border.width: 1
                            }

                            Drag.active: mouseArea.drag.active
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2
                            Drag.onActiveChanged: {
                                if (Drag.active) {
                                    parent = visualParent;
                                } else {
                                    const mapped = mapToItem(originalParent, 0, 0);
                                    parent = originalParent;

                                    if (toplevelData?.floating || !isCaught) {
                                        x = mapped.x;
                                        y = mapped.y;
                                    } else {
                                        x = localX * workspaceContainer.scaleFactor + centerOffsetX;
                                        y = localY * workspaceContainer.scaleFactor + centerOffsetY;
                                    }
                                }
                            }

                            MArea {
                                id: mouseArea

                                anchors.fill: parent

                                property bool dragged: false

                                drag.target: (toplevel.waylandHandle?.fullscreen || toplevel.waylandHandle?.maximized) ? undefined : toplevel
                                cursorShape: dragged ? Qt.DragMoveCursor : Qt.ArrowCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
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
                                        const nx = Math.round((mapped.x - toplevel.centerOffsetX) / workspaceContainer.scaleFactor + workspaceContainer.wsReserved[0] + workspaceContainer.monitorLogicalX);
                                        const ny = Math.round((mapped.y - toplevel.centerOffsetY) / workspaceContainer.scaleFactor + workspaceContainer.wsReserved[1] + workspaceContainer.monitorLogicalY);
                                        Hypr.dispatch("hl.movewindowpixel(\"exact " + nx + " " + ny + "\", \"address:0x" + toplevel.modelData.address + "\")");
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
