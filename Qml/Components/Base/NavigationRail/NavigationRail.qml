pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property var model: []
    property int currentIndex: 0
    property bool expanded: false

    property string fabIcon: ""
    property string fabLabel: ""
    signal fabTriggered

    property color backgroundColor: Colours.m3Colors.m3SurfaceContainerLow

    signal activated(int index)

    readonly property real compactWidth: 80
    readonly property real expandedWidth: 220

    property real animatedRailWidth: root.expanded ? root.expandedWidth : root.compactWidth

    implicitWidth: root.animatedRailWidth
    implicitHeight: parent ? parent.height : 480

    Behavior on animatedRailWidth {
        SpringAnimation {
            spring: 2
            damping: 0.2
        }
    }

    StyledRect {
        anchors.fill: parent
        color: root.backgroundColor
        radius: 0
    }

    Column {
        id: railColumn

        anchors.fill: parent
        anchors.topMargin: Appearance.margin.normal
        anchors.bottomMargin: Appearance.margin.normal
        spacing: Appearance.spacing.small

        Item {
            height: 40
            width: railColumn.width - Appearance.margin.normal * 2
            anchors.left: parent.left
            anchors.leftMargin: Appearance.margin.normal

            MArea {
                anchors.fill: parent
                anchors.rightMargin: parent.width - 40
                layerRadius: Appearance.rounding.full
                onClicked: root.expanded = !root.expanded

                Icon {
                    anchors.left: parent.left
                    anchors.leftMargin: (parent.width - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    icon: root.expanded ? "menu_open" : "menu"
                    font.pixelSize: Appearance.fonts.size.larger
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
            }
        }

        Item {
            visible: fabItem.visible
            width: 1
            height: Appearance.spacing.large - Appearance.spacing.small * 2
        }

        WrapperItem {
            id: fabItem

            visible: root.fabIcon !== ""
            implicitHeight: 56
            anchors.left: parent.left
            anchors.leftMargin: Appearance.margin.normal

            states: [
                State {
                    name: "compact"
                    when: !root.expanded

                    // qmllint disable Quick.property-changes-parsed
                    PropertyChanges {
                        target: fabItem
                        implicitWidth: 56
                    }
                },
                State {
                    name: "expanded"
                    when: root.expanded

                    PropertyChanges {
                        target: fabItem
                        implicitWidth: railColumn.width - Appearance.margin.normal * 2
                    }
                }
                // qmllint enable Quick.property-changes-parsed


            ]

            transitions: Transition {
                ParallelAnimation {
                    NAnim {
                        properties: "implicitWidth"
                    }
                }
            }

            MArea {
                layerRadius: Appearance.rounding.large
                layerRect.opacity: 0.0
                onClicked: root.fabTriggered()

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Colours.m3Colors.m3PrimaryContainer

                    Icon {
                        id: fabLeadingIcon

                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.margin.normal
                        anchors.verticalCenter: parent.verticalCenter
                        icon: root.fabIcon
                        font.pixelSize: Appearance.fonts.size.larger
                        color: Colours.m3Colors.m3OnPrimaryContainer
                    }

                    StyledText {
                        anchors.left: fabLeadingIcon.right
                        anchors.leftMargin: Appearance.spacing.normal
                        anchors.right: parent.right
                        anchors.rightMargin: Appearance.margin.normal
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fabLabel
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.Medium
                        color: Colours.m3Colors.m3OnPrimaryContainer
                        elide: Text.ElideRight
                        opacity: root.expanded ? 1 : 0

                        Behavior on opacity {
                            NAnim {}
                        }
                    }
                }
            }
        }

        Item {
            width: 1
            height: Appearance.spacing.large + Appearance.spacing.normal - Appearance.spacing.small * 2
        }

        Flickable {
            id: destinationsFlick

            width: railColumn.width
            height: railColumn.height - y
            contentWidth: width
            contentHeight: destinationsColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            boundsMovement: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            WheelHandler {
                target: destinationsFlick
                onWheel: event => {
                    const maxY = Math.max(0, destinationsFlick.contentHeight - destinationsFlick.height);
                    destinationsFlick.contentY = Math.max(0, Math.min(maxY, destinationsFlick.contentY - event.angleDelta.y));
                }
            }

            Column {
                id: destinationsColumn

                width: destinationsFlick.width
                spacing: railColumn.spacing

                Repeater {
                    model: root.model

                    delegate: NavigationRailItem {
                        required property int index
                        required property var modelData

                        x: (destinationsColumn.width - width) / 2
                        width: destinationsColumn.width - (root.expanded ? Appearance.margin.normal : Appearance.margin.smaller) * 2
                        height: implicitHeight

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
        }
    }
}
