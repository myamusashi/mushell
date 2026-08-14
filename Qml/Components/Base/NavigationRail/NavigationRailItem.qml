pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

WrapperItem {
    id: root

    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool expanded: false

    property string badgeText: ""
    property bool badgeDot: false

    signal triggered

    readonly property real compactPillHeight: 32
    readonly property real compactPillWidth: 56
    readonly property real expandedItemHeight: 56
    readonly property real compactLabelGap: 5
    readonly property real expandedLabelWidth: 124
    readonly property real iconCellSize: 24
    readonly property real iconCellX: Appearance.margin.normal

    implicitWidth: compactPillWidth
    implicitHeight: expanded ? Math.max(root.expandedItemHeight, labelText.implicitHeight) : root.compactPillHeight + root.compactLabelGap + labelText.implicitHeight

    leftMargin: root.expanded ? Appearance.margin.normal : Math.max(0, (root.width - root.compactPillWidth) / 2)
    rightMargin: leftMargin
    bottomMargin: root.expanded ? 0 : root.height - root.compactPillHeight

    MArea {
        id: area

        layerRadius: root.expanded ? Appearance.rounding.large : Appearance.rounding.full
        onClicked: root.triggered()

        layerRect.anchors.fill: undefined
        layerRect.x: background.x
        layerRect.y: background.y
        layerRect.width: background.width
        layerRect.height: background.height

        StyledRect {
            id: background

            x: root.expanded ? 0 : root.iconCellX + root.iconCellSize / 2 - root.compactPillWidth / 2
            y: 0
            width: root.expanded ? parent.width : parent.width - Appearance.margin.normal
            height: root.expanded ? root.expandedItemHeight : root.compactPillHeight
            radius: root.expanded ? Appearance.rounding.large : Appearance.rounding.full
            color: root.selected ? Colours.m3Colors.m3SecondaryContainer : "transparent"

            Behavior on color {
                CAnim {}
            }

            Behavior on x {
                SpringAnimation {
                    spring: 2
                    damping: 0.2
                }
            }
            Behavior on height {
                SpringAnimation {
                    spring: 2
                    damping: 0.2
                }
            }
        }

        Item {
            id: iconCell

            x: root.iconCellX
            width: root.iconCellSize
            height: root.iconCellSize
            anchors.verticalCenter: background.verticalCenter

            Icon {
                anchors.centerIn: parent
                icon: root.icon
                font.pixelSize: Appearance.fonts.size.larger
                color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

                Behavior on color {
                    CAnim {}
                }
            }

            RailBadge {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -4
                anchors.rightMargin: root.expanded ? -6 : -4
                text: root.badgeText
                dot: root.badgeDot
            }
        }

        StyledText {
            id: labelText

            readonly property real expandedLabelX: iconCell.x + iconCell.width + Appearance.spacing.normal
            readonly property real expandedLabelHeight: font.pixelSize * 1.2

            readonly property real compactX: (parent.width - root.compactPillWidth) / 2
            readonly property real compactY: root.compactPillHeight + root.compactLabelGap
            readonly property real expandedX: expandedLabelX
            readonly property real expandedY: (root.expandedItemHeight - expandedLabelHeight) / 2

            property real progress: root.expanded ? 1 : 0

            Behavior on progress {
                NAnim {
                    duration: Appearance.animations.durations.normal
                }
            }

            text: root.label
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: root.selected ? Font.Medium : Font.Normal
            color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface

            Behavior on color {
                CAnim {}
            }

            x: compactX + (expandedX - compactX) * progress
            y: compactY + (expandedY - compactY) * progress
            width: root.compactPillWidth + (root.expandedLabelWidth - root.compactPillWidth) * progress
        }
    }
}
