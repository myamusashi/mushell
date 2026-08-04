pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors
    readonly property bool focusedWsHasFullscreen: focusedWorkspace?.hasFullscreen

    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel?.wayland?.activated ? Hyprland.activeToplevel : null // qmllint disable
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    property var monitorData: ({})

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return Hyprland.monitorFor(screen);
    }

    signal configReloaded

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;
            if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon"))
                Hyprland.refreshMonitors();
            else if (n.includes("workspace"))
                Hyprland.refreshWorkspaces();
            else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n))
                Hyprland.refreshToplevels();
        }
    }

    Instantiator {
        model: root.monitors
        delegate: QtObject {
            required property HyprlandMonitor modelData

            Component.onCompleted: {
                let data = Object.assign({}, root.monitorData);

                data[modelData.name] = {
                    availableModes: modelData.lastIpcObject.availableModes,
                    description: modelData.description,
                    refreshRate: modelData.lastIpcObject.refreshRate,
                    resolution: modelData.width + "x" + modelData.height + "@" + modelData.lastIpcObject.refreshRate,
                    scale: modelData.scale,
                    colorManagementPreset: modelData.lastIpcObject.colorManagementPreset
                };
                root.monitorData = data;
            }
        }
    }
}
