pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

import "Components" as Com

Scope {
    id: scope

    property bool isNotificationCenterOpen: false

    OuterShapeItem {
        content: notifShape

        Shape {
            id: notifShape

            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 30
            }

            width: 350
            height: scope.isNotificationCenterOpen ? Hypr.focusedMonitor.height * 0.7 : 0
            clip: true
            visible: height > 0

            Behavior on height {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            ShapePath {
                strokeWidth: 0
                fillColor: outer.top.color
                startX: 12
                startY: 0

                PathLine {
                    x: notifShape.width - 12
                    y: 0
                }

                PathCubic {
                    control1X: notifShape.width - 5
                    control2X: notifShape.width
                    x: notifShape.width
                    y: 0
                }

                PathLine {
                    x: notifShape.width
                    y: notifShape.height - 12
                }

                PathArc {
                    x: notifShape.width - 12
                    y: notifShape.height
                    radiusX: 12
                    radiusY: 12
                }

                PathLine {
                    x: 12
                    y: notifShape.height
                }

                PathArc {
                    x: 0
                    y: notifShape.height - 12
                    radiusX: 12
                    radiusY: 12
                }

                PathLine {
                    x: 0
                    y: 12
                }

                PathCubic {
                    control1X: 0
                    control1Y: -15
                    control2X: -15
                    control2Y: 0
                    x: 12
                    y: 0
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Appearance.spacing.normal
                opacity: notifShape.height > 50 ? 1 : 0

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
                                    "icon": Notifs.disabledDnD ? "notifications_off" : "notifications_active",
                                    "action": () => {
                                        Notifs.disabledDnD = !Notifs.disabledDnD;
                                    }
                                }
                            ]

                            delegate: StyledRect {
                                id: notifHeaderDelegate

                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
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
                    color: "transparent"

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
                        contentHeight: notifColumn.height + 5
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
