pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Icon source for a pipewire node: prefers the application.icon-name
    // property, then resolves a desktop entry from the derived id
    function guessIconPath(node: PwNode): string {
        if (!node)
            return "image-missing";
        const iconName = node.properties["application.icon-name"];
        if (iconName)
            return Quickshell.iconPath(iconName, "image-missing");
        return root.iconForId(root.desktopId(node));
    }

    // Icon source for a desktop id, e.g. mpris player desktop entries
    function iconForId(desktopId: string): string {
        if (!desktopId)
            return "image-missing";
        if (["zen", "zen-twilight", "twilight"].includes(desktopId.toLowerCase())) {
            const zenIcon = Quickshell.hasThemeIcon("zen-beta") ? "zen-beta" : "zen-twilight";
            return Quickshell.iconPath(zenIcon, "image-missing");
        }
        return Quickshell.iconPath(DesktopEntries.heuristicLookup(desktopId)?.icon, "image-missing");
    }

    // Pipewire nodes don't carry a desktop id, so derive one from its properties
    function desktopId(node: PwNode): string {
        const appId = node.properties["application.id"];
        if (appId)
            return appId;
        const binary = node.properties["application.process.binary"];
        if (binary)
            return binary.split(".").pop();
        return node.name.split(".").pop();
    }
}