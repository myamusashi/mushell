pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components
import qs.Modules.Drawers.Notifications.Components as N

StyledRect {
    color: Colours.withAlpha(Colours.m3Colors.m3SurfaceContainer, 0.4)
    implicitWidth: parent.width * 0.5
    implicitHeight: parent.height

    Loader {
        anchors.fill: parent
        active: GlobalStates.isQuickSettingsOpen
        asynchronous: true

        sourceComponent: Column {
            anchors.fill: parent
            spacing: Appearance.spacing.small

            Row {
                width: parent.width
                height: 50
                visible: Notifs.notClosed.length > 0
                leftPadding: 10
                rightPadding: 10
                topPadding: 10
                spacing: parent.width * 0.01

                StyledRect {
                    height: 30
                    width: parent.width * 0.6 - parent.spacing
                    color: Colours.m3Colors.m3SurfaceContainer

                    StyledText {
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        text: "Clear all"
                    }

                    MArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }

                StyledRect {
                    height: 30
                    width: parent.width * 0.1
                    color: Colours.m3Colors.m3SurfaceContainer

                    Icon {
                        type: Icon.Material
                        anchors.centerIn: parent
                        icon: Notifs.dnd ? "notifications_off" : "notifications_active"
                        color: Colours.m3Colors.m3OnSurface
                    }

                    MArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
            }

            StyledRect {
                implicitWidth: parent.width
                implicitHeight: parent.height - (Notifs.notClosed.length > 0 ? 60 : 10)
                clip: true
                color: "transparent"

                ListView {
                    id: notifListView

                    anchors {
                        fill: parent
                        rightMargin: 10
                    }

                    model: ScriptModel {
                        values: [...Notifs.notClosed]
                    }

                    spacing: Appearance.spacing.normal
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: 200

                    delegate: Item {
                        id: root

                        required property var modelData
                        property bool isPopup: false
                        property alias contentLayout: contentLayout
                        property alias iconLayout: iconLayout
                        property alias mArea: delegateMouseNotif

                        signal entered
                        signal exited

                        implicitWidth: notifListView.width
                        implicitHeight: contentLayout.height * 1.3
                        clip: true
                        x: width

                        Component.onCompleted: {
                            slideInAnim.start();
                        }

                        Component.onDestruction: {
                            slideInAnim.stop();
                            slideOutAnim.start();
                            swipeOutAnim.start();
                        }

                        ListView.onReused: {
                            x = parent.width;
                            slideInAnim.start();
                        }

                        NAnim {
                            id: slideInAnim

                            target: root
                            property: "x"
                            from: root.width
                            to: 0
                            duration: Appearance.animations.durations.emphasized
                            easing.bezierCurve: Appearance.animations.curves.emphasized
                        }

                        NAnim {
                            id: slideOutAnim

                            target: root
                            property: "x"
                            to: root.width
                            duration: Appearance.animations.durations.emphasizedAccel
                            easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
                            onFinished: {
                                if (root.isPopup)
                                    root.modelData.popup = false;
                            }
                        }

                        NAnim {
                            id: swipeOutAnim

                            target: root
                            property: "x"
                            duration: Appearance.animations.durations.small
                            easing.bezierCurve: Appearance.animations.curves.standardAccel
                            onFinished: {
                                if (root.isPopup)
                                    root.modelData.popup = false;
                            }
                        }

                        Behavior on implicitWidth {
                            NAnim {
                                duration: Appearance.animations.durations.emphasized
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }

                        Behavior on implicitHeight {
                            NAnim {
                                duration: Appearance.animations.durations.emphasized
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }

                        StyledRect {
                            anchors {
                                fill: parent
                                leftMargin: 10
                            }
                            radius: Appearance.rounding.normal
                            clip: true

                            color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainer

                            border {
                                color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : "transparent"
                                width: root.modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                            }

                            MArea {
                                id: delegateMouseNotif

                                anchors.fill: parent
                                hoverEnabled: true

                                onEntered: {
                                    root.entered();
                                }

                                onExited: {
                                    root.exited();
                                }

                                drag {
                                    axis: Drag.XAxis
                                    target: root
                                    minimumX: -root.width
                                    maximumX: root.width

                                    onActiveChanged: {
                                        if (drag.active)
                                            return;

                                        if (Math.abs(root.x) > root.width * 0.45) {
                                            swipeOutAnim.to = root.x > 0 ? root.width : -root.width;
                                            swipeOutAnim.start();
                                            root.modelData.close();
                                        } else {
                                            root.x = 0;
                                        }
                                    }
                                }
                            }

                            Row {
                                anchors {
                                    fill: parent
                                    topMargin: 10
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                spacing: Appearance.spacing.normal

                                N.Icon {
                                    id: iconLayout

                                    modelData: root.modelData
                                }

                                N.Content {
                                    id: contentLayout

                                    modelData: root.modelData
                                }
                            }
                        }
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
