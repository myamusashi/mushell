pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Notifications

import qs.Configs
import qs.Services
import qs.Components

import "Components" as Com

Scope {
    id: notificationScope

    property bool hasNotifications: Notifs.notifications.popupNotifications.length > 0
    property bool triggerAnimation: false
    property bool shouldDestroy: false

    onHasNotificationsChanged: {
        if (hasNotifications) {
            shouldDestroy = false;
            triggerAnimation = false;
            animationTriggerTimer.restart();
        } else {
            triggerAnimation = false;
            destroyTimer.restart();
        }
    }

    Timer {
        id: animationTriggerTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (notificationScope.hasNotifications) {
                notificationScope.triggerAnimation = true;
            }
        }
    }

    Timer {
        id: destroyTimer
        interval: Appearance.animations.durations.small + 50
        repeat: false
        onTriggered: {
            notificationScope.shouldDestroy = true;
        }
    }

    LazyLoader {
        loading: notificationScope.hasNotifications
        activeAsync: notificationScope.hasNotifications || !notificationScope.shouldDestroy

        component: OuterShapeItem {
            content: item

            StyledRect {
                id: item

                anchors {
                    right: parent.right
                    top: parent.top
                }

				width: Hypr.focusedMonitor.width * 0.2
				height: notificationScope.triggerAnimation ? Math.min(notifColumn.height + 30, parent.height * 0.4) : 0
				color: Themes.m3Colors.m3Background
                radius: 0
				bottomLeftRadius: Appearance.rounding.normal

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


                Flickable {
					id: notifFlickable

                    anchors.fill: parent
                    contentHeight: notifColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
						id: notifColumn

                        width: parent.width
                        spacing: Appearance.spacing.normal

                        Repeater {
                            id: notifRepeater

                            model: ScriptModel {
                                values: [...Notifs.notifications.popupNotifications.map(a => a)].reverse()
                            }

                            delegate: Com.Wrapper {
                                id: wrapper

                                onEntered: closePopups.stop()
                                onExited: closePopups.start()

                                Timer {
									id: closePopups

                                    interval: wrapper.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000
                                    running: true
                                    onTriggered: wrapper.removeNotificationWithAnimation()
                                }

                                Timer {
                                    id: removeTimer
                                    interval: Appearance.animations.durations.emphasizedAccel + 50
                                    onTriggered: Notifs.notifications.removePopupNotification(wrapper.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
