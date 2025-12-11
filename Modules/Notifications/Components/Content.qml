pragma ComponentBehavior: Bound

import QtQuick

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Column {
    id: root

    required property var modelData
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

                    text: root.modelData.appName
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.Medium
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    elide: Text.ElideRight
                }

                StyledText {
                    id: dots

                    text: "•"
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                }

                StyledText {
                    id: whenTime

                    property date notificationDate: root.modelData.time
                    text: TimeAgo.timeAgoWithIfElse(notificationDate)
                    color: Colours.m3Colors.m3OnSurfaceVariant

                    Timer {
                        interval: 60000
                        running: true
                        repeat: true
                        onTriggered: whenTime.text = TimeAgo.timeAgoWithIfElse(whenTime.notificationDate)
                    }
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
                font.pixelSize: Appearance.fonts.size.extraLarge
                color: Colours.m3Colors.m3OnSurfaceVariant
            }

            MArea {
                id: expandButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.isShowMoreBody = !root.isShowMoreBody
            }
        }
    }

    StyledText {
        id: summary

        width: parent.width
        text: root.modelData.summary
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        color: Colours.m3Colors.m3OnSurface
        elide: Text.ElideRight
        wrapMode: Text.Wrap
        maximumLineCount: 2
    }

    StyledText {
        id: body

        width: parent.width
        text: root.modelData.body || ""
        font.pixelSize: Appearance.fonts.size.medium
        color: Colours.m3Colors.m3OnSurface
        textFormat: Text.StyledText
        maximumLineCount: root.isShowMoreBody ? 0 : 1
        wrapMode: Text.Wrap
    }

    Row {
        width: parent.width
        topPadding: 8
        spacing: Appearance.spacing.normal
        visible: root.modelData?.actions && root.modelData.actions.length > 0

        Repeater {
            model: root.modelData?.actions

            delegate: StyledRect {
                id: actionButton

                required property var modelData

                width: (parent.width - parent.children.length - 1) / parent.children.length + 10
                height: 40
                color: Colours.m3Colors.m3SurfaceContainerHigh
                radius: Appearance.rounding.full
                StyledRect {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                }
                MArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: actionButton.modelData.invoke()
                }
                StyledText {
                    anchors.centerIn: parent
                    text: actionButton.modelData.text
                    font.pixelSize: Appearance.fonts.size.medium
                    font.weight: Font.Medium
                    color: Colours.m3Colors.m3OnBackground
                    elide: Text.ElideRight
                }
            }
        }
    }
}
