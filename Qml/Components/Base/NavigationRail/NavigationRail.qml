pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    // Model items: [{ icon, label, badgeText?, badgeDot? }, ...]
    property var model: []
    property int currentIndex: 0
    property bool expanded: false

    // Optional primary/FAB-style action shown below the toggle.
    // Leave fabIcon empty to omit it entirely.
    property string fabIcon: ""
    property string fabLabel: ""
    signal fabTriggered

    property color backgroundColor: Colours.m3Colors.m3SurfaceContainerLow

    signal activated(int index)

    readonly property real compactWidth: 80
    readonly property real expandedWidth: 220

    // Animated internal width: implicitWidth cannot carry a Behavior because
    // it is bound, so toggling triggers an explicit NumberAnimation instead.
    property real animatedRailWidth: root.expanded ? root.expandedWidth : root.compactWidth

    implicitWidth: root.animatedRailWidth
    implicitHeight: parent ? parent.height : 480

    onExpandedChanged: {
        railWidthAnimation.stop();
        railWidthAnimation.to = root.expanded ? root.expandedWidth : root.compactWidth;
        railWidthAnimation.start();
    }

    NumberAnimation {
        id: railWidthAnimation

        target: root
        property: "animatedRailWidth"
        duration: Appearance.animations.durations.normal
        easing.bezierCurve: Appearance.animations.curves.emphasized
    }

    StyledRect {
        anchors.fill: parent
        color: root.backgroundColor
        radius: 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Appearance.margin.normal
        anchors.bottomMargin: Appearance.margin.normal
        spacing: Appearance.spacing.large

        // Toggle button, icon-only. Alignment grid (per mode):
        // - expanded: full width inset by margin.normal, icon at left+normal
        // - compact:  56px footprint centered on the column, icon centered
        // Explicit width keeps the resize off Layout pixel-quantization.
        Item {
            Layout.preferredHeight: 40
            width: root.expanded ? parent.width - Appearance.margin.normal * 2 : 56 // qmllint disable
            Layout.alignment: Qt.AlignHCenter

            MArea {
                anchors.fill: parent
                layerRadius: Appearance.rounding.full
                onClicked: root.expanded = !root.expanded

                Icon {
                    anchors.left: parent.left
                    // Compact centered via leftMargin compensation instead of
                    // switching anchors (conditional anchors stick after the
                    // first mode change). Expanded: left-inset grid point.
                    anchors.leftMargin: root.expanded ? Appearance.margin.normal : parent.width / 2 - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    icon: root.expanded ? "menu_open" : "menu"
                    font.pixelSize: Appearance.fonts.size.larger
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
            }
        }

        // Optional FAB-style primary action, same alignment grid as the
        // toggle: expanded full width inset by margin.normal, compact
        // centered 56px footprint.
        Item {
            visible: root.fabIcon !== ""
            Layout.preferredHeight: 56
            width: root.expanded ? parent.width - Appearance.margin.normal * 2 : 56 // qmllint disable
            Layout.alignment: Qt.AlignHCenter

            MArea {
                anchors.fill: parent
                layerRadius: Appearance.rounding.large
                onClicked: root.fabTriggered()

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Colours.m3Colors.m3PrimaryContainer

                    // Expanded: icon + label row on the left-inset grid
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.margin.normal
                        anchors.rightMargin: Appearance.margin.normal
                        spacing: Appearance.spacing.normal
                        visible: root.expanded

                        Icon {
                            icon: root.fabIcon
                            font.pixelSize: Appearance.fonts.size.larger
                            color: Colours.m3Colors.m3OnPrimaryContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.fabLabel
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.Medium
                            color: Colours.m3Colors.m3OnPrimaryContainer
                            elide: Text.ElideRight
                        }
                    }

                    // Compact: icon centered in the 56px footprint
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.normal
                        visible: !root.expanded

                        Icon {
                            icon: root.fabIcon
                            font.pixelSize: Appearance.fonts.size.larger
                            color: Colours.m3Colors.m3OnPrimaryContainer
                        }
                    }
                }
            }
        }

        // Destination items, explicit width (Layout would pixel-quantize the
        // animated resize).
        ColumnLayout {
            width: parent.width // qmllint disable
            Layout.topMargin: Appearance.spacing.normal
            spacing: Appearance.spacing.small

            Repeater {
                model: root.model

                NavigationRailItem {
                    required property int index
                    required property var modelData

                    width: parent.width - (root.expanded ? Appearance.margin.normal : Appearance.margin.smaller) * 2 // qmllint disable

                    icon: modelData.icon ?? ""
                    label: modelData.label ?? ""
                    badgeText: modelData.badgeText ?? ""
                    badgeDot: modelData.badgeDot ?? false
                    selected: index === root.currentIndex
                    expanded: root.expanded

                    onTriggered: {
                        root.currentIndex = index;
                        root.activated(index);
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
