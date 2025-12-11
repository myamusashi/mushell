pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import "Components"

StyledRect {
    id: root

    property bool isNotificationCenterOpen: GlobalStates.isNotificationCenterOpen

    anchors {
        right: parent.right
        top: parent.top
    }

    width: Hypr.focusedMonitor.width * 0.25
    height: isNotificationCenterOpen ? Hypr.focusedMonitor.height * 0.7 : 0
    clip: true
    radius: 0
    anchors.leftMargin: 15
    bottomLeftRadius: Appearance.rounding.normal
    visible: height > 0
    color: Colours.m3Colors.m3Background

    Behavior on width {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        anchors.fill: parent
        active: root.isNotificationCenterOpen
        asynchronous: true
        sourceComponent: ColumnLayout {
            anchors.fill: parent
            spacing: Appearance.spacing.normal
            opacity: root.height > 50 ? 1 : 0

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: header.height + 30
                Layout.margins: 5
                Layout.alignment: Qt.AlignTop
                color: "transparent"

                RowLayout {
                    id: header

                    anchors.fill: parent
                    anchors.margins: 10

                    StyledText {
                        Layout.fillWidth: true
                        text: "Notifications"
                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.large * 1.2
                        font.weight: Font.Medium
                    }

                    Repeater {
                        model: [
                            {
                                "icon": "clear_all",
                                "action": () => Notifs.clearAll()
                            },
                            {
                                "icon": Notifs.dnd ? "notifications_off" : "notifications_active",
                                "action": () => {
                                    Notifs.dnd = !Notifs.dnd;
                                }
                            }
                        ]

                        delegate: StyledRect {
                            id: notifHeaderDelegate

                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            color: iconMouse.containsMouse ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"

                            required property var modelData

                            MaterialIcon {
                                anchors.centerIn: parent
                                icon: notifHeaderDelegate.modelData.icon
                                font.pointSize: Appearance.fonts.size.extraLarge * 0.6
                                color: Colours.m3Colors.m3OnSurface
                            }

                            MArea {
                                id: iconMouse

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: notifHeaderDelegate.modelData.action()
                            }
                        }
                    }
                }
            }

            StyledRect {
                color: Colours.m3Colors.m3OutlineVariant
                Layout.fillWidth: true
                implicitHeight: 1
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                ListView {
                    id: notifListView

                    anchors {
                        fill: parent
                        leftMargin: 15
                        rightMargin: 15
                    }

                    model: ScriptModel {
                        values: [...Notifs.notClosed]
                    }
                    spacing: Appearance.spacing.normal
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    cacheBuffer: 300
                    reuseItems: true

                    delegate: Wrapper {
                        required property var modelData
                        required property int index

                        notif: modelData
                        width: notifListView.width
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.medium
                    visible: Notifs.notClosed.length === 0
                    opacity: 0.6
                }
            }
        }
    }
}
