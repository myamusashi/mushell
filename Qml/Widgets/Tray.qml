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

    property var glidePopup: null
    property var glideItem: null
    property var glideFrom: null
    property var glideTo: null
    property real glideProgress: 0
    readonly property int maxMenuDepth: 3

    implicitWidth: visible ? systemTrayRow.width + horizontalPadding * 1.2 : 0
    implicitHeight: 35
    radius: Appearance.rounding.small
    color: "transparent"
    visible: SystemTray.items.values.length > 0

    Behavior on implicitWidth {
        NAnim {}
    }

    onGlideProgressChanged: {
        if (!root.glidePopup || !root.glideFrom || !root.glideTo)
            return;
        const progress = root.glideProgress;
        root.glidePopup.glideX = (root.glideTo.x - root.glideFrom.x) * progress;
        root.glidePopup.glideY = (root.glideTo.y - root.glideFrom.y) * progress;
        if (progress >= 1) {
            if (root.glidePopup && root.glideItem)
                root.glidePopup.positionAt(root.glideItem); // qmllint disable
            root.glidePopup.glideX = 0;
            root.glidePopup.glideY = 0;
            root.glidePopup = null;
            root.glideItem = null;
            root.glideFrom = null;
            root.glideTo = null;
        }
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
                    property color colorFrom
                    property color colorTo
                    property bool colorBlending: false
                    property real colorBlendProgress: 1.0
                    onColorBlendProgressChanged: {
                        if (!colorBlending)
                            return;
                        if (colorBlendProgress >= 1) {
                            color = colorTo;
                            colorBlending = false;
                        } else if (colorBlendProgress > 0) {
                            color = Colours.blendColors(colorFrom, colorTo, colorBlendProgress);
                        }
                    }
                    onTargetChanged: {
                        colorBlendAnim.stop();
                        colorFrom = color;
                        colorTo = target;
                        colorBlending = true;
                        colorBlendProgress = 0.0;
                        colorBlendAnim.start();
                    }

                    width: 25
                    height: 25
                    radius: Appearance.rounding.normal

                    NAnim {
                        id: colorBlendAnim
                        target: bgTrayIcon
                        property: "colorBlendProgress"
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
        interval: Appearance.animations.durations.normal
        onTriggered: root.closeMenu()
    }

    Timer {
        id: hideTimer
        interval: Appearance.animations.durations.expressiveDefaultSpatial
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
        const rootPopup = root.levelAt(0);
        if (!rootPopup) {
            root.activeIconItem = iconItem;
            const popup = root.createLevel(0, item.menu, iconItem, iconItem.QsWindow.window); // qmllint disable
            root.menuLevels = [popup];
            return;
        }

        root.pruneLevels(0);
        rootPopup.handle = item.menu; // qmllint disable
        if (rootPopup.anchorWindow !== iconItem.QsWindow.window) { // qmllint disable
            rootPopup.anchorWindow = iconItem.QsWindow.window; // qmllint disable
        }
        if (root.activeIconItem === iconItem && rootPopup.menuOpen) // qmllint disable
            return;
        root.glideToPosition(rootPopup, iconItem);
        rootPopup.visible = true;
        rootPopup.menuOpen = true;
        root.activeIconItem = iconItem;
    }

    function createLevel(level: int, handle, anchorItem, anchorWindow): QtObject {
        const popup = popupComponent.createObject(null, {
            level: level,
            handle: handle,
            anchorWindow: anchorWindow
        });
        popup.entryHovered.connect((entry, entryItem) => root.onEntryHovered(popup, entry, entryItem));
        popup.entryClicked.connect(entry => root.onEntryClicked(entry));
        popup.entered.connect(() => {
            closeTimer.stop();
            hideTimer.stop();
        });
        popup.exited.connect(() => root.scheduleClose());
        popup.closed.connect(() => root.popupClosed(popup));
        popup.positionAt(anchorItem);
        popup.menuOpen = true;
        popup.visible = true;
        return popup;
    }

    function glideToPosition(popup, item): void {
        const fromX = popup.anchor.rect.x; // qmllint disable
        const fromY = popup.anchor.rect.y; // qmllint disable
        const to = popup.computePosition(item);
        if (!to)
            return;
        root.glidePopup = popup;
        root.glideItem = item;
        root.glideFrom = {
            x: fromX,
            y: fromY
        };
        root.glideTo = to;
        glideAnim.restart();
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

        if (entry.hasChildren && popup.level + 1 < root.maxMenuDepth) { // qmllint disable
            root.pruneLevels(level + 1);
            let child = root.levelAt(level + 1);
            if (child) {
                child.handle = entry;
                child.anchorWindow = popup;
                child.glideX = 0;
                child.glideY = 0;
                child.positionAt(entryItem); // qmllint disable
                child.visible = true;
                child.menuOpen = true;
            } else {
                const created = root.createLevel(level + 1, entry, entryItem, popup);
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
        root.glidePopup = null;
        root.glideFrom = null;
        root.glideTo = null;
    }

    NAnim {
        id: glideAnim

        target: root
        property: "glideProgress"
        from: 0
        to: 1
        duration: Appearance.animations.durations.expressiveDefaultSpatial
        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
    }

    component TrayMenuPopup: PopupWindow {
        id: popup

        required property int level
        required property var handle
        required property var anchorWindow
        property bool menuOpen: false
        property real glideX: 0
        property real glideY: 0
        property real shadowPadding: 12

        signal entryHovered(var entry, var entryItem)
        signal entryClicked(var entry)
        signal entered
        signal exited

        implicitWidth: trayMenu.menuWidth
        implicitHeight: Math.min(trayMenu.contentHeight, trayMenu.maxHeight) + shadowPadding
        color: "transparent"
        mask: Region {
            item: menuHost
        }

        anchor {
            window: popup.anchorWindow
            edges: { // qmllint disable missing-type
                if (popup.level === 0)
                    return Edges.Bottom | Edges.Left;
                if (popup.level === 1)
                    return Edges.Top | Edges.Right;
                if (popup.level === 2)
                    return Edges.Bottom | Edges.Left;
            }
            gravity: Edges.Bottom | Edges.Right // qmllint disable missing-type
            adjustment: { // qmllint disable missing-type
                if (popup.level === 0)
                    return PopupAdjustment.Flip | PopupAdjustment.Slide | PopupAdjustment.ResizeY;
                if (popup.level === 1)
                    return PopupAdjustment.FlipX | PopupAdjustment.FlipY | PopupAdjustment.SlideY | PopupAdjustment.ResizeY;
                if (popup.level === 2)
                    return PopupAdjustment.Flip | PopupAdjustment.Slide | PopupAdjustment.ResizeY;
            }
            margins {
                bottom: 0
                right: popup.level === 0 ? 0 : -6
            }
        }

        function computePosition(item): var {
            let mapped;
            const contentItem = popup.anchorWindow.contentItem;
            if (contentItem)
                mapped = contentItem.mapFromItem(item, 0, 0, item.width, item.height);
            if (!mapped)
                return null;
            if (popup.level === 0) {
                const barBottom = (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) + Configs.bar.barHeight;
                return {
                    x: mapped.x,
                    y: barBottom - mapped.height,
                    w: mapped.width,
                    h: mapped.height
                };
            }
            return {
                x: mapped.x,
                y: mapped.y,
                w: mapped.width,
                h: mapped.height
            };
        }

        function positionAt(item): void {
            const target = popup.computePosition(item);
            if (!target)
                return;
            // qmllint disable
            popup.anchor.rect.x = target.x;
            popup.anchor.rect.y = target.y;
            popup.anchor.rect.w = target.w;
            popup.anchor.rect.h = target.h;
            popup.anchor.updateAnchor();
            // qmllint enable
        }

        Item {
            id: menuHost

            x: popup.glideX
            y: popup.glideY
            width: trayMenu.width
            height: trayMenu.height

            TrayMenu {
                id: trayMenu

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
}
