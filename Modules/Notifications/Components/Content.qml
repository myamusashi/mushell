pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications

import qs.Helpers
import qs.Configs
import qs.Services
import qs.Components

Column {
    id: root

    required property Notification notif
    property bool isShowMoreBody: false

    width: parent.width
    spacing: Appearance.spacing.small

    Row {
        width: parent.width
        spacing: Appearance.spacing.small

        Item {
            width: parent.width - expandButton.width - parent.spacing
            height: appNameRow.height

            Row {
				id: appNameRow

				spacing: Appearance.spacing.normal

                StyledText {
                    id: appName

                    text: root.notif.appName
                    font.pixelSize: Appearance.fonts.large
                    font.weight: Font.Medium
                    color: Themes.m3Colors.m3OnSurfaceVariant
                    elide: Text.ElideRight
                }

                StyledText {
                    id: dots

                    text: "•"
                    color: Themes.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.large
                }

                StyledText {
                    id: whenTime

                    text: {
                        const now = new Date();
                        return TimeAgo.timeAgoWithIfElse(now);
                    }
                    color: Themes.m3Colors.m3OnSurfaceVariant
                }
            }
        }

        StyledRect {
            id: expandButton

            width: 32
            height: 32
            radius: Appearance.rounding.large
            color: "transparent"
            MaterialIcon {
                id: expandIcon

                anchors.centerIn: parent
                icon: root.isShowMoreBody ? "expand_less" : "expand_more"
                font.pointSize: Appearance.fonts.large
                color: Themes.m3Colors.m3OnSurfaceVariant
                RotationAnimator on rotation {
                    id: rotateArrowIcon

                    from: 0
                    to: 180
                    duration: Appearance.animations.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animations.curves.standard
                    running: false
                }
            }
            MArea {
                id: expandButtonMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.isShowMoreBody = !root.isShowMoreBody;
                    rotateArrowIcon.running = !rotateArrowIcon.running;
                }
            }
        }
    }

    StyledText {
        id: summary

        width: parent.width
        text: root.notif.summary
        font.pixelSize: Appearance.fonts.medium
        font.weight: Font.DemiBold
        color: Themes.m3Colors.m3OnSurface
        elide: Text.ElideRight
        wrapMode: Text.Wrap
        maximumLineCount: 2
    }

    StyledText {
        id: body

        width: parent.width
        text: root.notif.body || ""
        font.pixelSize: Appearance.fonts.medium
        color: Themes.m3Colors.m3OnSurface
        textFormat: Text.StyledText
        maximumLineCount: root.isShowMoreBody ? 0 : 1
		wrapMode: Text.Wrap
    }

    Row {
        width: parent.width
        topPadding: 8
        spacing: Appearance.spacing.normal
        visible: root.notif?.actions && root.notif.actions.length > 0

        Repeater {
            model: root.notif?.actions
            delegate: StyledRect {
                id: actionButton

                width: (parent.width - (parent.spacing * (parent.children.length - 1))) / parent.children.length
                height: 40
                required property NotificationAction modelData
                color: actionMouse.pressed ? Themes.m3Colors.m3SecondaryContainer : actionMouse.containsMouse ? Themes.m3Colors.m3SecondaryContainer : Themes.m3Colors.m3SurfaceContainerHigh
                radius: Appearance.rounding.full
                StyledRect {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                }
                MArea {
                    id: actionMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        actionButton.modelData.invoke();
                        Notifs.notifications.removePopupNotification(root.notif);
                        Notifs.notifications.removeListNotification(root.notif);
                    }
                }
                StyledText {
                    anchors.centerIn: parent
                    text: actionButton.modelData.text
                    font.pixelSize: Appearance.fonts.small
                    font.weight: Font.Medium
                    color: Themes.m3Colors.m3OnSecondaryContainer
                    elide: Text.ElideRight
                }
            }
        }
    }
}
