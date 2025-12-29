import QtQuick
import Quickshell

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components
import qs.Modules.Notifications.Components as N

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

                    MaterialIcon {
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
                width: parent.width
                height: parent.height - (Notifs.notClosed.length > 0 ? 60 : 10)
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

                    delegate: N.Wrapper {
                        required property var modelData
                        required property int index
                        notif: modelData
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
