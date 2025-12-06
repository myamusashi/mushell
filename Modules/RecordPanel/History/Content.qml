pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

import qs.Helpers
import qs.Configs
import qs.Components

Column {
    id: root

    required property var modelData

    width: parent.width
    spacing: Appearance.spacing.small

    Row {
        width: parent.width
        spacing: Appearance.spacing.small

        Item {
            width: parent.width - parent.spacing
            height: appNameRow.height

            Row {
                id: appNameRow

                spacing: Appearance.spacing.normal

                StyledText {
                    text: "Screen capture"
                    font.pixelSize: Appearance.fonts.large
                    font.weight: Font.Medium
                    color: Themes.m3Colors.m3OnSurfaceVariant
                    elide: Text.ElideRight
                }

                StyledText {
                    text: "•"
                    color: Themes.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.large
                }

                StyledText {
                    text: root.modelData.created
                    color: Themes.m3Colors.m3OnSurfaceVariant
                }
            }
        }
    }

    StyledText {
        width: parent.width
        text: root.modelData.name
        font.pixelSize: Appearance.fonts.medium
        font.weight: Font.DemiBold
        color: Themes.m3Colors.m3OnSurface
        elide: Text.ElideRight
        wrapMode: Text.Wrap
        maximumLineCount: 2
    }

    StyledText {
        width: parent.width
        text: root.modelData.path
        font.pixelSize: Appearance.fonts.medium
        color: Themes.m3Colors.m3OnSurface
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
    }

    StyledRect {
        width: (parent.width - parent.children.length - 1) / parent.children.length + 10
        height: 40
        color: Themes.m3Colors.m3SurfaceContainerHigh
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
			onClicked: () => {
				Quickshell.execDetached({
					command: ["sh", "-c", `yazi ${root.modelData.path}`]
				})
			}
        }
        StyledText {
            anchors.centerIn: parent
            text: "Open files"
            font.pixelSize: Appearance.fonts.medium
            font.weight: Font.Medium
            color: Themes.m3Colors.m3OnBackground
            elide: Text.ElideRight
        }
    }
}
