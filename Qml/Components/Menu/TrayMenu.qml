pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.States

Item {
    id: root

    required property QsMenuHandle handle
    property bool open: false
    property bool horizontal: false
    property real maxHeight: 800
    property real menuWidth: 280

    signal entryHovered(var entry, var entryItem)
    signal entryClicked(var entry)
    signal entered
    signal exited

    readonly property real contentHeight: menuColumn.implicitHeight

    width: root.horizontal ? (root.open ? root.menuWidth : 1) : root.menuWidth
    height: root.open ? Math.min(root.contentHeight, root.maxHeight) : 1

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on width {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    QsMenuOpener {
        id: menuOpener

        menu: root.handle
    }

    Elevation {
        anchors.fill: surfaceBg
        level: 2
        radius: surfaceBg.radius
    }

    WrapperRectangle {
        id: surfaceBg

        anchors.fill: parent
        radius: 0
        color: GlobalStates.drawerColors
        clip: true

        Column {
            id: menuColumn

            width: root.menuWidth
            padding: Appearance.padding.smaller
            spacing: 2

            Repeater {
                model: menuOpener.children

                delegate: TrayMenuItem {
                    id: itemRow

                    width: menuColumn.width - menuColumn.padding * 2

                    onHovered: root.entryHovered(modelData, itemRow)
                    onActivated: root.entryClicked(modelData)
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler

        onHoveredChanged: {
            if (hoverHandler.hovered)
                root.entered();
            else
                root.exited();
        }
    }
}
