import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Vast.Clipboard

import qs.Core.States
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

ItemDelegate {
    id: root

    required property int index
    required property var entryId
    required property string type
    required property string preview
    required property bool pinned
    required property string sourceApp
    required property var timestamp
    required property string fileName
    required property bool isSelected

    readonly property bool isImage: root.type === "image"
    readonly property bool isFiles: root.type === "files"

    readonly property string formattedTime: {
        const d = new Date(root.timestamp);
        const now = new Date();
        const diff = now - d;

        if (diff < 60000)
            return qsTr("just now");
        if (diff < 3600000)
            return qsTr("%1m ago").arg(Math.floor(diff / 60000));
        if (diff < 86400000)
            return qsTr("%1h ago").arg(Math.floor(diff / 3600000));
        return d.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
    }

    signal activated
    signal pinToggled(var id, bool pinned)
    signal removeRequested(var id)

    width: ListView.view?.width ?? parent?.width ?? 320
    height: 64
    hoverEnabled: true
    highlighted: root.isSelected
    onClicked: root.activated()

    background: Rectangle {
        radius: Appearance.rounding.small
        color: "transparent"

        Rectangle {
            anchors {
                left: parent.left
                leftMargin: 2
                verticalCenter: parent.verticalCenter
            }
            implicitWidth: 3
            implicitHeight: parent.height - Appearance.margin.large
            radius: 2
            color: Colours.m3Colors.m3Primary
            visible: root.pinned
        }
    }

    contentItem: RowLayout {
        spacing: Appearance.spacing.smaller

        Item {
            Layout.preferredWidth: root.pinned ? Appearance.margin.large - Appearance.margin.normal : 0
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 32
            implicitHeight: 32
            radius: Appearance.rounding.small
            color: {
                switch (root.type) {
                case "image":
                    return Qt.alpha(Colours.m3Colors.m3Blue, 0.2);
                case "html":
                    return Qt.alpha(Colours.m3Colors.m3Tertiary, 0.2);
                case "files":
                    return Qt.alpha(Colours.m3Colors.m3Green, 0.2);
                default:
                    return Qt.alpha(Colours.m3Colors.m3OnSurface, 0.06);
                }
            }

            Icon {
                anchors.centerIn: parent
                icon: {
                    switch (root.type) {
                    case "image":
                        return "image";
                    case "html":
                        return "code";
                    case "files":
                        return "folder";
                    default:
                        return "notes";
                    }
                }
                font.pixelSize: Appearance.fonts.size.large
                color: {
                    switch (root.type) {
                    case "image":
                        return Colours.m3Colors.m3Blue;
                    case "html":
                        return Colours.m3Colors.m3Tertiary;
                    case "files":
                        return Colours.m3Colors.m3Green;
                    default:
                        return Colours.m3Colors.m3OnSurface;
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            StyledText {
                readonly property int fileCount: root.isFiles ? root.preview.split("\n").length : 0

                Layout.fillWidth: true
                text: root.isImage ? (root.fileName || qsTr("Image")) : root.isFiles ? qsTr("Files (%1)").arg(fileCount) : root.preview || qsTr("(empty)")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.medium
                maximumLineCount: 2
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: Appearance.spacing.small
                visible: root.sourceApp !== ""

                StyledText {
                    text: root.sourceApp
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    elide: Text.ElideRight
                    Layout.maximumWidth: 120
                }

                StyledText {
                    text: "·"
                    color: Colours.m3Colors.m3OutlineVariant
                    font.pixelSize: Appearance.fonts.size.small
                }

                StyledText {
                    text: root.formattedTime
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                }
            }
        }

        Item {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            visible: root.hovered || root.pinned
            opacity: pinArea.containsMouse ? 1.0 : 0.6

            Behavior on opacity {
                NAnim {}
            }

            Icon {
                anchors.centerIn: parent
                icon: root.pinned ? "keep" : "keep_off"
                font.pixelSize: Appearance.fonts.size.large
                color: root.pinned ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            }

            MouseArea {
                id: pinArea

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.pinToggled(root.entryId, !root.pinned)
            }
        }
    }

    TapHandler {
        onDoubleTapped: {
            ClipboardManager.copyToClipboard(root.entryId);
            GlobalStates.isClipboardOpen = false;
        }
    }
}
