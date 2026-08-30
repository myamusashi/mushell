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

    property string actionButtonIcon: ""
    property string actionButtonLabel: ""
    signal actionButtonTriggered

    property color backgroundColor: Colours.m3Colors.m3SurfaceContainerLow

    signal activated(int index)

    function sectionBaseIndex(sectionIndex) {
        let sum = 0;
        for (let i = 0; i < sectionIndex; i++)
            sum += model[i]?.items?.length ?? 0;
        return sum;
    }

    readonly property real compactWidth: 80
    readonly property real expandedWidth: 220

    property real animatedRailWidth: expanded ? expandedWidth : compactWidth

    implicitWidth: animatedRailWidth
    implicitHeight: parent ? parent.height : 480

    Behavior on animatedRailWidth {
        SpringAnimation {
            spring: 3
            damping: 0.3
            mass: 1
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
            visible: actionButtonItem.visible
            width: 1
            height: Appearance.spacing.large - Appearance.spacing.small * 2
        }

        WrapperItem {
            id: actionButtonItem

            visible: root.actionButtonIcon !== ""
            implicitHeight: 56
            anchors.left: parent.left
            anchors.leftMargin: Appearance.margin.normal

            states: [
                State {
                    name: "compact"
                    when: !root.expanded

                    // qmllint disable Quick.property-changes-parsed
                    PropertyChanges {
                        target: actionButtonItem
                        implicitWidth: 56
                    }
                },
                State {
                    name: "expanded"
                    when: root.expanded

                    PropertyChanges {
                        target: actionButtonItem
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
                onClicked: root.actionButtonTriggered()

                StyledRect {
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Colours.m3Colors.m3PrimaryContainer

                    Icon {
                        id: actionButtonLeadingIcon

                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.margin.normal
                        anchors.verticalCenter: parent.verticalCenter
                        icon: root.actionButtonIcon
                        font.pixelSize: Appearance.fonts.size.larger
                        color: Colours.m3Colors.m3OnPrimaryContainer
                    }

                    StyledText {
                        anchors.left: actionButtonLeadingIcon.right
                        anchors.leftMargin: Appearance.spacing.normal
                        anchors.right: parent.right
                        anchors.rightMargin: Appearance.margin.normal
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.actionButtonLabel
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

                    delegate: Column {
                        id: sectionColumn

                        required property int index
                        required property var modelData

                        readonly property int baseIndex: root.sectionBaseIndex(index)
                        readonly property int topGap: index === 0 ? Appearance.spacing.small : Appearance.spacing.large

                        width: destinationsColumn.width
                        spacing: 0

                        Item {
                            id: sectionHeader

                            width: parent.width
                            height: root.expanded ? sectionColumn.topGap + headerLabel.implicitHeight + Appearance.spacing.small : 0

                            Behavior on height {
                                NAnim {}
                            }

                            StyledText {
                                id: headerLabel

                                anchors.left: parent.left
                                anchors.leftMargin: Appearance.margin.normal
                                anchors.right: parent.right
                                anchors.rightMargin: Appearance.margin.normal
                                anchors.verticalCenter: parent.verticalCenter
                                text: sectionColumn.modelData.label ?? ""
                                font.pixelSize: Appearance.fonts.size.large
                                font.weight: Font.Medium
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                elide: Text.ElideRight
                                opacity: root.expanded ? 1 : 0

                                Behavior on opacity {
                                    NAnim {}
                                }
                            }
                        }

                        Repeater {
                            model: sectionColumn.modelData.items ?? []

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
                                selected: sectionColumn.baseIndex + index === root.currentIndex
                                expanded: root.expanded

                                onTriggered: {
                                    root.currentIndex = sectionColumn.baseIndex + index;
                                    root.activated(sectionColumn.baseIndex + index);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
