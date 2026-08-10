pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    default property alias content: itemColumn.data
    property int elevationLevel: 2
    property real maxHeight: 336

    readonly property real minWidth: 112
    readonly property real maxWidth: 280

    implicitWidth: Math.max(root.minWidth, Math.min(root.maxWidth, itemColumn.implicitWidth))
    implicitHeight: Math.min(root.maxHeight, itemColumn.implicitHeight)

    Elevation {
        anchors.fill: surfaceBg
        level: root.elevationLevel
        radius: surfaceBg.radius
    }

    WrapperRectangle {
        id: surfaceBg

        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Colours.m3Colors.m3SurfaceContainer
        clip: true

        Flickable {
            id: itemFlickable

            clip: true
            contentHeight: itemColumn.implicitHeight

            Column {
                id: itemColumn

                width: parent.width
                padding: Appearance.padding.smaller
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded

                contentItem: StyledRect {
                    implicitWidth: 4
                    radius: 2
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                }
            }
        }
    }
}
