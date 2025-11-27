pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

import "Components" as Com

Scope {
    id: scope

    property bool isNotificationCenterOpen: false

    LazyLoader {
        active: scope.isNotificationCenterOpen

        component: PanelWindow {
            id: root

            anchors {
                top: true
                right: true
            }

            property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
            property real monitorWidth: monitor.width / monitor.scale
            property real monitorHeight: monitor.height / monitor.scale
            implicitWidth: monitorWidth * 0.25
            implicitHeight: monitorHeight * 0.8
            exclusiveZone: 1

            color: "transparent"

            margins {
                right: 30
                left: (monitorWidth - implicitWidth) / 1.5
            }

            StyledRect {
                id: container

                anchors.fill: parent
                color: Themes.m3Colors.m3Surface

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.normal

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
                                color: Themes.m3Colors.m3OnBackground
                                font.pixelSize: Appearance.fonts.large * 1.2
                                font.weight: Font.Medium
                            }

                            Repeater {
                                model: [
                                    {
                                        "icon": "clear_all",
                                        "action": () => {
                                            Notifs.notifications.dismissAll();
                                        }
                                    },
                                    {
                                        "icon": Notifs.notifications.disabledDnD ? "notifications_off" : "notifications_active",
                                        "action": () => {
                                            Notifs.notifications.disabledDnD = !Notifs.notifications.disabledDnD;
                                        }
                                    }
                                ]

                                delegate: StyledRect {
                                    id: notifHeaderDelegate

                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    radius: 6
                                    color: iconMouse.containsMouse ? Themes.m3Colors.m3SurfaceContainerHigh : "transparent"

                                    required property var modelData

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        icon: notifHeaderDelegate.modelData.icon
                                        font.pointSize: Appearance.fonts.extraLarge * 0.6
                                        color: Themes.m3Colors.m3OnSurface
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
                        color: Themes.m3Colors.m3OutlineVariant
                        Layout.fillWidth: true
                        implicitHeight: 1
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Flickable {
                            id: notifFlickable

                            anchors {
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                leftMargin: 15
                                rightMargin: 15
                            }

                            width: parent.width
                            contentHeight: notifColumn.height + 32
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: notifColumn

                                width: parent.width
                                spacing: Appearance.spacing.normal

                                Repeater {
                                    id: notifRepeater

                                    model: ScriptModel {
                                        values: [...Notifs.notifications.listNotifications.map(a => a)].reverse()
                                    }

                                    delegate: Com.Wrapper {}
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
