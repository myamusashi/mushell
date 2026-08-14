pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Modules.Drawers.Notifications.Components as N

StyledRect {
    property alias loader: loader

    radius: Appearance.rounding.normal
    color: Qt.alpha(Colours.m3Colors.m3SurfaceContainer, 0.4)

    RowLayout {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 10
        }
        implicitWidth: parent.width
        implicitHeight: 50
        spacing: Appearance.spacing.small

        Item {
            Layout.fillWidth: true
        }

        StyledRect {
            FontMetrics {
                id: clearMetrics

                font: textClear.font
            }
            implicitWidth: clearMetrics.advanceWidth(textClear.text) + 100
            implicitHeight: 30
            color: Colours.m3Colors.m3SurfaceContainer

            StyledText {
                id: textClear

                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                text: qsTr("Clear all")
            }

            MArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.clearAll()
            }
        }

        StyledRect {
            implicitWidth: 30
            implicitHeight: 30
            color: Colours.m3Colors.m3SurfaceContainer

            Icon {
                id: iconDnD

                type: Icon.Material
                anchors.centerIn: parent
                icon: Notifs.dnd ? "notifications_off" : "notifications_active"
                font.pixelSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface
            }

            MArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.dnd = !Notifs.dnd
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Loader {
        id: loader

        anchors {
            fill: parent
            topMargin: 50
            bottomMargin: 10
        }
        active: GlobalStates.isQuickSettingsOpen
        asynchronous: true

        sourceComponent: StyledRect {
            anchors.fill: parent
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
                cacheBuffer: 0
                spacing: Appearance.spacing.normal
                boundsBehavior: Flickable.StopAtBounds
                delegate: WrapperItem {
                    id: root

                    required property var modelData

                    implicitWidth: notifListView.width
                    implicitHeight: contentLayout.height * 1.3
                    leftMargin: 10
                    clip: true

                    NAnim {
                        id: swipeOutAnim

                        target: root
                        property: "x"
                        duration: Appearance.animations.durations.small

                        onFinished: {
                            fadeOutAnim.start();
                        }
                    }

                    NAnim {
                        id: fadeOutAnim

                        target: root
                        property: "opacity"
                        from: 1.0
                        to: 0.0
                        duration: Appearance.animations.durations.small
                    }

                    SpringAnimation {
                        id: springBackAnim

                        target: root
                        property: "x"
                        to: 0
                        spring: 2
                        damping: 0.3
                    }

                    Timer {
                        id: closeTimer

                        interval: swipeOutAnim.duration + fadeOutAnim.duration
                        onTriggered: root.modelData.close()
                    }

                    WrapperRectangle {
                        color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainer
                        border {
                            color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : "transparent"
                            width: root.modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                        }
                        margin: Appearance.margin.normal
                        radius: Appearance.rounding.normal
                        clip: true

                        Item {
                            MArea {
                                id: delegateMouseNotif

                                anchors.fill: parent
                                hoverEnabled: true

                                drag {
                                    axis: Drag.XAxis
                                    target: root
                                    minimumX: -root.width
                                    maximumX: root.width

                                    onActiveChanged: {
                                        if (drag.active)
                                            return;
                                        const swipeThreshold = root.width * 0.35;

                                        if (Math.abs(root.x) > swipeThreshold) {
                                            swipeOutAnim.to = root.x > 0 ? root.width * 1.2 : -root.width * 1.2;
                                            swipeOutAnim.start();
                                            closeTimer.start();
                                        } else {
                                            springBackAnim.start();
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

                                N.NotifIcon {
                                    id: iconLayout

                                    modelData: root.modelData
                                }

                                N.Content {
                                    id: contentLayout

                                    width: parent.width - iconLayout.width
                                    modelData: root.modelData
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: qsTr("No notifications")
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.medium
                visible: Notifs.notClosed.length === 0
                opacity: 0.6
            }
        }
    }
}
