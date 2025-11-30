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
    id: notifCenterScope

    property bool isNotificationCenterOpen: false

    // Properties untuk orchestrate animasi
    property bool triggerAnimation: false
    property bool shouldDestroy: false

    onIsNotificationCenterOpenChanged: {
        if (isNotificationCenterOpen) {
            // Buka: reset → tunggu load → trigger animasi
            shouldDestroy = false;
            triggerAnimation = false;
            animationTriggerTimer.restart();
        } else {
            // Tutup: trigger animasi → tunggu selesai → destroy
            triggerAnimation = false;
            destroyTimer.restart();
        }
    }

    Timer {
        id: animationTriggerTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (notifCenterScope.isNotificationCenterOpen) {
                notifCenterScope.triggerAnimation = true;
            }
        }
    }

    Timer {
        id: destroyTimer
        interval: Appearance.animations.durations.small + 50
        repeat: false
        onTriggered: {
            notifCenterScope.shouldDestroy = true;
        }
    }

    LazyLoader {
        id: scope

        loading: notifCenterScope.isNotificationCenterOpen
        activeAsync: notifCenterScope.isNotificationCenterOpen || !notifCenterScope.shouldDestroy

        component: OuterShapeItem {
            content: notifShape

			StyledRect {
                id: notifShape

                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: 30
                }

                width: 350
                height: notifCenterScope.triggerAnimation ? Hypr.focusedMonitor.height * 0.7 : 0
				clip: true
				radius: 0
				bottomRightRadius: Appearance.rounding.normal
				bottomLeftRadius: Appearance.rounding.normal
				visible: height > 0
				color: Themes.m3Colors.m3Background

                Behavior on height {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
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
}
