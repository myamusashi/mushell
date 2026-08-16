pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    property alias widgetHeight: root.implicitHeight
    readonly property real horizontalPadding: Appearance.spacing.normal

    property var activeIconItem: null
    property var menuLevels: []

    implicitWidth: visible ? systemTrayRow.width + horizontalPadding * 1.2 : 0
    implicitHeight: 35
    radius: Appearance.rounding.small
    color: "transparent"
    visible: SystemTray.items.values.length > 0

    Behavior on implicitWidth {
        NAnim {}
    }

    Row {
        id: systemTrayRow

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Repeater {
            model: SystemTray.items.values
            delegate: Item {
                id: delegateTray

                required property SystemTrayItem modelData
                property string iconSource: {
                    let icon = modelData && modelData.icon;
                    if (typeof icon === 'string' || icon instanceof String) {
                        if (icon.includes("?path=")) {
                            const split = icon.split("?path=");
                            if (split.length !== 2)
                                return icon;
                            const name = split[0];
                            const path = split[1];
                            const fileName = name.substring(name.lastIndexOf("/") + 1);
                            return "file://" + path + "/" + fileName;
                        }
                        return icon;
                    }
                    return "";
                }

                width: 25
                height: 25

                StyledRect {
                    id: bgTrayIcon
                    property color target: trayItemArea.containsMouse ? Colours.m3Colors.m3Primary : "transparent"
                    property color cFrom
                    property color cTo
                    property bool cActive: false
                    property real cBlend: 1.0
                    onCBlendChanged: {
                        if (!cActive)
                            return;
                        if (cBlend >= 1) {
                            color = cTo;
                            cActive = false;
                        } else if (cBlend > 0) {
                            color = Colours.blendColors(cFrom, cTo, cBlend);
                        }
                    }
                    onTargetChanged: {
                        cAnim.stop();
                        cFrom = color;
                        cTo = target;
                        cActive = true;
                        cBlend = 0.0;
                        cAnim.start();
                    }

                    width: 25
                    height: 25
                    radius: Appearance.rounding.normal

                    NAnim {
                        id: cAnim
                        target: bgTrayIcon
                        property: "cBlend"
                        from: 0.0
                        to: 1.0
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    width: Appearance.fonts.size.large * 1.2
                    height: Appearance.fonts.size.large * 1.2
                    source: parent.iconSource
                    asynchronous: true
                    backer.cache: true
                    smooth: true
                    mipmap: true
                }

                MArea {
                    id: trayItemArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.openMenuFor(delegateTray.modelData, delegateTray)
                    onExited: root.scheduleClose()
                    onClicked: mouse => {
                        if (!delegateTray.modelData || mouse.button !== Qt.LeftButton)
                            return;
                        if (delegateTray.modelData.hasMenu && delegateTray.modelData.onlyMenu)
                            return;
                        delegateTray.modelData.activate();
                    }
                }
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: root.closeMenu()
    }

    Timer {
        id: hideTimer
        interval: Appearance.animations.durations.expressiveDefaultSpatial + 60
        onTriggered: root.finishClose()
    }

    Component {
        id: popupComponent

        TrayMenuPopup {}
    }

    function openMenuFor(item, iconItem): void {
        closeTimer.stop();
        hideTimer.stop();
        if (!item || !item.hasMenu) {
            root.closeMenu();
            return;
        }
        if (root.activeIconItem === iconItem && root.menuLevels.length > 0) {
            if (root.menuLevels[0].menuOpen)
                return;
            for (const levelPopup of root.menuLevels)
                levelPopup.menuOpen = true;
            return;
        }

        root.destroyLevels(0);
        const oldRoot = root.menuLevels.find(levelPopup => levelPopup.level === 0);
        if (oldRoot) {
            root.menuLevels.splice(root.menuLevels.indexOf(oldRoot), 1);
            oldRoot.visible = false;
            oldRoot.destroy();
        }

        root.activeIconItem = iconItem;

        const popup = root.createLevel(0, item.menu, iconItem); // qmllint disable
        root.menuLevels = [popup];
    }

    function createLevel(level: int, handle, anchorItem): QtObject {
        const popup = popupComponent.createObject(null, {
            level: level,
            handle: handle
        });
        popup.entryHovered.connect((entry, entryItem) => root.onEntryHovered(popup, entry, entryItem));
        popup.entryClicked.connect(entry => root.onEntryClicked(entry));
        popup.entered.connect(() => {
            closeTimer.stop();
            hideTimer.stop();
        });
        popup.exited.connect(() => root.scheduleClose());
        popup.closed.connect(() => root.popupClosed(popup));
        popup.anchor.item = anchorItem;
        popup.anchor.updateAnchor();
        popup.menuOpen = true;
        popup.visible = true;
        return popup;
    }

    function popupClosed(popup): void {
        if (popup.level === 0) {
            root.finishClose();
            return;
        }
        root.destroyLevels(popup.level - 1);
        if (root.menuLevels.length === 0) {
            closeTimer.stop();
            hideTimer.stop();
            root.activeIconItem = null;
        }
    }

    function onEntryHovered(popup, entry, entryItem): void {
        if (!entry)
            return;
        closeTimer.stop();
        hideTimer.stop();

        const level = popup.level;

        if (entry.hasChildren) { // qmllint disable
            root.pruneLevels(level + 1);
            let child = root.levelAt(level + 1);
            if (child) {
                child.handle = entry;
                child.anchor.item = entryItem; // qmllint disable
                child.anchor.updateAnchor(); // qmllint disable
                child.visible = true;
                child.menuOpen = true;
            } else {
                const created = root.createLevel(level + 1, entry, entryItem); // qmllint disable
                root.menuLevels.push(created);
            }
        } else {
            root.pruneLevels(level);
        }
    }

    function onEntryClicked(entry): void {
        root.closeMenu();
    }

    function pruneLevels(keepMaxLevel: int): void {
        for (const levelPopup of root.menuLevels) {
            if (levelPopup.level <= keepMaxLevel)
                continue;
            levelPopup.menuOpen = false;
            levelPopup.visible = false;
            levelPopup.handle = null;
        }
    }

    function levelAt(level: int): QtObject {
        for (const levelPopup of root.menuLevels) {
            if (levelPopup.level === level)
                return levelPopup;
        }
        return null;
    }

    function destroyLevels(keepBelowLevel: int): void {
        const sorted = root.menuLevels.slice().sort((a, b) => b.level - a.level);
        for (const levelPopup of sorted) {
            if (levelPopup.level > keepBelowLevel) {
                const index = root.menuLevels.indexOf(levelPopup);
                if (index >= 0)
                    root.menuLevels.splice(index, 1);
                levelPopup.visible = false;
                levelPopup.destroy();
            }
        }
    }

    function scheduleClose(): void {
        if (root.menuLevels.length === 0)
            return;
        closeTimer.restart();
    }

    function closeMenu(): void {
        closeTimer.stop();
        hideTimer.stop();
        if (root.menuLevels.length === 0)
            return;
        for (const levelPopup of root.menuLevels)
            levelPopup.menuOpen = false;
        hideTimer.restart();
    }

    function finishClose(): void {
        closeTimer.stop();
        root.destroyLevels(-1);
        root.menuLevels = [];
        root.activeIconItem = null;
    }

    component TrayMenuPopup: PopupWindow {
        id: popup

        required property int level
        required property var handle
        property bool menuOpen: false

        signal entryHovered(var entry, var entryItem)
        signal entryClicked(var entry)
        signal entered
        signal exited

        implicitWidth: trayMenu.menuWidth
        implicitHeight: trayMenu.maxHeight
        color: "transparent"
        mask: Region {
            item: trayMenu
        }

        anchor {
            item: null
            edges: popup.level === 0 ? (Edges.Bottom | Edges.Left) : (Edges.Top | Edges.Right)
            gravity: Edges.Bottom | Edges.Right
            adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
            margins {
                bottom: popup.level === 0 ? -6 : 0
                right: popup.level === 0 ? 0 : -6
            }
        }

        TrayMenu {
            id: trayMenu

            anchors.top: parent.top
            anchors.left: parent.left
            handle: popup.handle
            open: popup.menuOpen
            horizontal: popup.level > 0

            onEntryHovered: (entry, entryItem) => popup.entryHovered(entry, entryItem)
            onEntryClicked: entry => popup.entryClicked(entry)
            onEntered: popup.entered()
            onExited: popup.exited()
        }
    }
}
