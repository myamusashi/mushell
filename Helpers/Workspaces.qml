pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
	id: hyprland

	property list<HyprlandWorkspace> workspaces: sortWorkspaces(Hyprland.workspaces.values)
	property int maxWorkspace: findMaxId()

	function sortWorkspaces(ws) {
		return [...ws].sort((a, b) => a?.id - b?.id);
	}

	function switchWorkspace(w: int): void {
		Hyprland.dispatch("workspace" + w);
	}

	function findMaxId(): int {
		if (hyprland.workspaces.length === 0) {
			return 1;
			// Return 1 if no workspaces exist
		}
		let num = hyprland.workspaces.length;
		let maxId = hyprland.workspaces[num - 1]?.id || 1;
		return maxId;
	}

	Connections {
		target: Hyprland
		function onRawEvent(event) {
			let eventName = event.name;

			switch (eventName) {
			case "createworkspacev2":
			{
				hyprland.workspaces = hyprland.sortWorkspaces(Hyprland.workspaces.values);
				hyprland.maxWorkspace = hyprland.findMaxId();
			}
			case "destroyworkspacev2":
			{
				hyprland.workspaces = hyprland.sortWorkspaces(Hyprland.workspaces.values);
				hyprland.maxWorkspace = hyprland.findMaxId();
			}
			}
		}
	}
}
