pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Menu

Popup {
    id: root

    property Item anchorItem: null
    property alias model: itemRepeater.model
    property int currentIndex: -1
    property var textRole: "text"
    property var isItemEnabled: modelData => true
    property var disabledLabel: modelData => ""
    property var isItemActive: (modelData, itemIndex) => itemIndex === currentIndex
    property bool showScrollBar: false

    /// Flip policy. "auto" picks up/down from available window space.
    /// Use "down" or "up" to force a direction.
    property string preferredDirection: "auto"

    /// Minimum visible rows when we have to cap height to stay on-screen.
    property int minVisibleRows: 3

    signal activated(int index)

    padding: 0
    background: null
    focus: true
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

    readonly property bool openingUpward: openUpward
    readonly property int gap: 4

    property bool openUpward: false
    property real resolvedMaxHeight: 336
    property bool resolveGuard: false

    width: anchorItem ? Math.max(menuSurface.minWidth, Math.min(menuSurface.maxWidth, anchorItem.width)) : menuSurface.implicitWidth
    y: openUpward ? -height - gap : (anchorItem ? anchorItem.height + gap : 0)
    height: Math.min(resolvedMaxHeight, menuSurface.contentImplicitHeight)

    transformOrigin: openUpward ? Popup.BottomLeft : Popup.TopLeft

    onAnchorItemChanged: {
        if (anchorItem)
            parent = anchorItem;
    }

    onAboutToShow: resolvePlacement()
    onOpened: resolvePlacement()

    function resolvePlacement() {
        if (!anchorItem || !anchorItem.QsWindow.window)
            return;
        if (resolveGuard)
            return;
        resolveGuard = true;

        // qmllint disable missing-property
        const win = anchorItem.QsWindow.window;
        const availAbove = availableSpaceAbove();
        const availBelow = availableSpaceBelow();

        const desired = menuSurface.contentImplicitHeight;
        const maxCap = 336;

        const rowH = 48;
        const minH = Math.min(maxCap, Math.max(80, minVisibleRows * rowH));

        let openUp = false;
        let resolvedMax = maxCap;

        if (preferredDirection === "up") {
            openUp = true;
            resolvedMax = Math.min(maxCap, Math.max(minH, availAbove - gap));
        } else if (preferredDirection === "down") {
            openUp = false;
            resolvedMax = Math.min(maxCap, Math.max(minH, availBelow - gap));
        } else {
            const fitsBelow = desired <= (availBelow - gap);
            const fitsAbove = desired <= (availAbove - gap);
            if (fitsBelow)
                openUp = false;
            else if (fitsAbove)
                openUp = true;
            else if (availAbove > availBelow)
                openUp = true;
            else
                openUp = false;

            const avail = openUp ? availAbove : availBelow;
            resolvedMax = Math.min(maxCap, Math.max(minH, avail - gap));
        }

        if (win.height > 0)
            resolvedMax = Math.min(resolvedMax, win.height - 24);
        // qmllint enable missing-property

        openUpward = openUp;
        resolvedMaxHeight = resolvedMax;

        resolveGuard = false;
    }

    function availableSpaceBelow(): real {
        const win = anchorItem ? anchorItem.QsWindow.window : null;
        if (!win)
            return 336 + 200;
        // qmllint disable missing-property
        const contentItem = win.contentItem;
        if (contentItem) {
            const p = anchorItem.mapToItem(contentItem, 0, anchorItem.height);
            if (isFinite(p.y))
                return win.height - p.y - gap;
        }
        return win.height - (anchorItem.height + gap);
        // qmllint enable missing-property
    }

    function availableSpaceAbove(): real {
        const win = anchorItem ? anchorItem.QsWindow.window : null;
        if (!win)
            return 336 + 200;
        // qmllint disable missing-property
        const contentItem = win.contentItem;
        if (contentItem) {
            const p = anchorItem.mapToItem(contentItem, 0, 0);
            if (isFinite(p.y))
                return p.y - gap;
        }
        return win.height;
        // qmllint enable missing-property
    }

    Connections {
        target: root.anchorItem && root.anchorItem.QsWindow.window ? root.anchorItem.QsWindow.window : null
        ignoreUnknownSignals: true

        function onWidthChanged() {
            root.resolvePlacement();
        }
        function onHeightChanged() {
            root.resolvePlacement();
        }
        function onXChanged() {
            root.resolvePlacement();
        }
        function onYChanged() {
            root.resolvePlacement();
        }
    }

    MenuSurface {
        id: menuSurface

        anchors.fill: parent
        showScrollBar: root.showScrollBar
        maxHeight: root.resolvedMaxHeight

        Repeater {
            id: itemRepeater

            model: root.model

            delegate: MenuItem {
                required property int index
                required property var modelData

                label: typeof modelData === "string" ? modelData : modelData[root.textRole] ?? ""
                // qmllint disable
                selected: root.isItemActive(modelData, index)
                disabledLabel: root.disabledLabel(modelData)
                enabled: root.isItemEnabled(modelData)
                // qmllint enable

                onTriggered: {
                    root.activated(index);
                    root.close();
                }
            }
        }
    }

    enter: Transition {
        ParallelAnimation {
            NAnim {
                property: "opacity"
                from: 0.0
                to: 1.0
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
            NAnim {
                property: "scale"
                from: 0.8
                to: 1.0
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NAnim {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
            NAnim {
                property: "scale"
                from: 1.0
                to: 0.8
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
        }
    }
}
