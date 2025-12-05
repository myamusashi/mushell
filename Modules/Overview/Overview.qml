// Thx M7moud El-zayat for your Overview code
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Scope {
    id: scope

    property real scaleFactor: 0.2
    property real borderWidth: 2
    property bool wallpaperEnabled: true

    GlobalShortcut {
        name: "overview"
        onPressed: lazyloader.active = !lazyloader.active
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: gc()
    }

    LazyLoader {
        id: lazyloader

        active: false
        onActiveChanged: {
            cleanup.start();
        }
        component: PanelWindow {
            id: root

            property real workspaceWidth: (Hypr.focusedMonitor.width - (root.reserved[0] + root.reserved[2])) * scope.scaleFactor / Hypr.focusedMonitor.scale
            property real workspaceHeight: (Hypr.focusedMonitor.height - (root.reserved[1] + root.reserved[3])) * scope.scaleFactor / Hypr.focusedMonitor.scale
            property real containerWidth: workspaceWidth + scope.borderWidth
            property real containerHeight: workspaceHeight + scope.borderWidth
            property list<int> reserved: Hypr.focusedMonitor.lastIpcObject.reserved

            implicitWidth: contentGrid.implicitWidth * 2.5
            implicitHeight: contentGrid.implicitHeight * 2.5
            color: "transparent"
            WlrLayershell.namespace: "shell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            StyledRect {
                color: Themes.m3Colors.m3Background
                border.color: Themes.m3Colors.m3Outline
                anchors.fill: contentGrid
                anchors.margins: -12
            }

            // Overlay Layer
            StyledRect {
                id: overLayer

                color: "transparent"
                z: 1
                anchors.fill: parent
            }

            // Workspaces Grid
            GridLayout {
                id: contentGrid

                rows: 2
                columns: 4
                rowSpacing: 12

                columnSpacing: 12
                anchors.centerIn: parent

                // Workspaces Containers
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
                        border.width: 2

                        border.color: hasMaximized ? "red" : workspace?.focused ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OnPrimary

                        clip: true

                        FileView {
                            id: wallid

                            path: Qt.resolvedUrl(Paths.currentWallpaperFile)
                            watchChanges: true
                            onFileChanged: reload()
                        }

                        Loader {
                            active: scope.wallpaperEnabled
                            visible: active
                            anchors.centerIn: parent

                            sourceComponent: Image {
                                source: wallid.text().trim()
                                sourceSize.width: root.workspaceWidth
                                width: workspaceContainer.width - 10
                                height: workspaceContainer.height - 10
                                fillMode: Image.PreserveAspectCrop
                                smooth: false
                                cache: true
                            }
                        }

                        // Toplevel DropArea
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

                        // Toplevels
                        Repeater {
                            model: parent.workspace?.toplevels

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

                                width: sourceSize.width * scope.scaleFactor / Hypr.focusedMonitor.scale
                                height: sourceSize.height * scope.scaleFactor / Hypr.focusedMonitor.scale
                                scale: (Drag.active && !toplevelData?.floating) ? 0.75 : 1

                                x: (toplevelData?.at[0] - (waylandHandle?.fullscreen ? 0 : root.reserved[0])) * scope.scaleFactor + scope.borderWidth + 12
                                y: (toplevelData?.at[1] - (waylandHandle?.fullscreen ? 0 : root.reserved[1])) * scope.scaleFactor + scope.borderWidth + 12
                                z: (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 2 : toplevelData?.floating ? 1 : 0

                                Behavior on x {
                                    NAnim {
                                        easing.bezierCurve: Appearance.animations.curves.emphasized
                                        duration: Appearance.animations.durations.normal
                                    }
                                }

                                Behavior on scale {
                                    NAnim {
                                        easing.bezierCurve: Appearance.animations.curves.emphasized
                                        duration: Appearance.animations.durations.normal
                                    }
                                }

                                Behavior on y {
                                    NAnim {
                                        easing.bezierCurve: Appearance.animations.curves.emphasized
                                        duration: Appearance.animations.durations.normal
                                    }
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
                                            x = !isCaught ? mapped.x : (toplevelData?.at[0] - (waylandHandle?.fullscreen ? 0 : root.reserved[0])) * scope.scaleFactor + scope.borderWidth + 12;
                                            y = !isCaught ? mapped.y : (toplevelData?.at[1] - (waylandHandle?.fullscreen ? 0 : root.reserved[1])) * scope.scaleFactor + scope.borderWidth + 12;
                                        }
                                    }
                                }

                                IconImage {
                                    source: Quickshell.iconPath(DesktopEntries.heuristicLookup(toplevel.waylandHandle?.appId)?.icon, "image-missing")
                                    implicitSize: 48
                                    backer.cache: true
                                    backer.asynchronous: true
                                    anchors.centerIn: parent
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
                                            if (mouse.button === Qt.LeftButton)
                                            toplevel.waylandHandle.activate();
                                            else if (mouse.button === Qt.RightButton)
                                            toplevel.waylandHandle.close();
                                        }
                                    }

                                    onReleased: {
                                        if (dragged && !(toplevel.waylandHandle?.fullscreen || toplevel.waylandHandle?.maximized)) {
                                            const mapped = toplevel.mapToItem(toplevel.originalParent, 0, 0);
                                            const x = Math.round(mapped.x / scope.scaleFactor + root.reserved[0]);
                                            const y = Math.round(mapped.y / scope.scaleFactor + root.reserved[1]);

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
}
