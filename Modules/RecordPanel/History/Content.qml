pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Helpers
import qs.Configs
import qs.Components

Column {
    id: root

    required property var modelData

    function getFileExtension(filepath) {
        const filename = filepath.split('/').pop();
        const lastDot = filename.lastIndexOf('.');
        if (lastDot === -1 || lastDot === 0)
            return '';
        return filename.substring(lastDot + 1).toLowerCase();
    }

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
                    text: {
                        const timestamp = root.modelData.created;
                        const date = new Date(timestamp * 1000);
                        return date.toLocaleString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric',
                            hour: 'numeric',
                            minute: '2-digit',
                            hour12: true
                        });
                    }
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
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const data = root.getFileExtension(root.modelData.path);
                switch (data) {
                case "mkv":
                case "mp3":
                case "mp4":
                    Quickshell.execDetached({
                        command: ["mpv", root.modelData.path]
                    });
                    break;
                case "png":
                case "jpg":
                case "jpeg":
                case "gif":
                case "ico":
                    Quickshell.execDetached({
                        command: ["lximage-qt", root.modelData.path]
                    });
                    break;
                }
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
