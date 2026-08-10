pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool expanded: false

    // Badge: set badgeText for a numeric/short count, or badgeDot: true
    // for a plain unread-style dot. badgeText takes priority if both set.
    property string badgeText: ""
    property bool badgeDot: false

    signal triggered

    readonly property real compactPillHeight: 32
    readonly property real compactPillWidth: 56
    readonly property real expandedItemHeight: 56

    // implicitWidth must not depend on parent width: containers stretch this
    // item via Layout.fillWidth, and a parent-relative implicit size would
    // create a recursive rearrange with Qt Quick Layouts.
    // Compact mode is icon-only (no label), per M3 rail design.
    implicitWidth: compactPillWidth
    implicitHeight: expanded ? Math.max(root.expandedItemHeight, expandedLabelText.implicitHeight) : compactPillHeight

    Behavior on implicitHeight {
        NAnim {}
    }

    MArea {
        id: area

        anchors.fill: parent
        layerRadius: root.expanded ? Appearance.rounding.large : Appearance.rounding.full
        onClicked: root.triggered()

        // Compact layout: centered pill + icon, no label
        ColumnLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.smaller
            visible: !root.expanded
            opacity: root.expanded ? 0 : 1

            Behavior on opacity {
                NAnim {}
            }

            StyledRect {
                id: compactPill

                Layout.preferredWidth: root.compactPillWidth
                Layout.preferredHeight: root.compactPillHeight
                Layout.alignment: Qt.AlignHCenter
                radius: Appearance.rounding.full
                color: root.selected ? Colours.m3Colors.m3SecondaryContainer : "transparent"

                Icon {
                    anchors.centerIn: parent
                    icon: root.icon
                    font.pixelSize: Appearance.fonts.size.larger
                    color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                }

                RailBadge {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -4
                    anchors.rightMargin: -4
                    text: root.badgeText
                    dot: root.badgeDot
                }
            }
        }

        // Expanded layout: full-width pill, icon+label inline, badge trailing
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.margin.normal
            anchors.rightMargin: Appearance.margin.normal
            spacing: Appearance.spacing.normal
            visible: root.expanded
            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NAnim {}
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.large
                color: root.selected ? Colours.m3Colors.m3SecondaryContainer : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.margin.normal
                    anchors.rightMargin: Appearance.margin.normal
                    spacing: Appearance.spacing.normal

                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24

                        Icon {
                            anchors.centerIn: parent
                            icon: root.icon
                            font.pixelSize: Appearance.fonts.size.large
                            color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                        }

                        RailBadge {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -4
                            anchors.rightMargin: -6
                            text: root.badgeText
                            dot: root.badgeDot
                        }
                    }

                    StyledText {
                        id: expandedLabelText

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        text: root.label
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: root.selected ? Font.Medium : Font.Normal
                        color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
                    }
                }
            }
        }
    }
}
