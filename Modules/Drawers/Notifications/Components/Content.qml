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

    width: parent.width - iconLayout.width - parent.spacing
    spacing: Appearance.spacing.small

    Row {
        width: parent.width
        spacing: Appearance.spacing.small

        Row {
            id: appInfoRow

            width: parent.width - expandButton.width - parent.spacing
            spacing: Appearance.spacing.normal

            StyledText {
                text: root.modelData.appName
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.Medium
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
            }

            StyledText {
                text: "•"
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.large
            }

            StyledText {
                id: timeText

                text: TimeAgo.timeAgoWithIfElse(root.modelData.time)
                color: Colours.m3Colors.m3OnSurfaceVariant

                Timer {
                    interval: 60000
                    running: true
                    repeat: true
                    onTriggered: timeText.text = TimeAgo.timeAgoWithIfElse(root.modelData.time)
                }
            }
        }

        StyledRect {
            id: expandButton

            implicitWidth: 32
            implicitHeight: 32
            radius: Appearance.rounding.large
            color: "transparent"

            Icon {
                anchors.centerIn: parent
                icon: root.isShowMoreBody ? "expand_less" : "expand_more"
                font.pixelSize: Appearance.fonts.size.extraLarge
                color: Colours.m3Colors.m3OnSurfaceVariant
            }

            MArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.isShowMoreBody = !root.isShowMoreBody
            }
        }
    }

    StyledText {
        width: parent.width
        text: root.modelData.summary
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        color: Colours.m3Colors.m3OnSurface
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }

    StyledText {
        width: parent.width
        text: root.modelData.body || ""
        font.pixelSize: Appearance.fonts.size.medium
        color: Colours.m3Colors.m3OnSurface
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: root.isShowMoreBody ? 0 : 1
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
                required property int index

                implicitWidth: {
                    const count = root.modelData.actions.length;
                    const totalSpacing = (count - 1) * Appearance.spacing.normal;
                    return (parent.width - totalSpacing) / count;
                }
                implicitHeight: 40
                radius: Appearance.rounding.full
                color: Colours.m3Colors.m3SurfaceContainerHigh

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
