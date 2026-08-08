import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Vast.Clipboard

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Feedback

Item {
    id: root

    property int entryId: -1

    signal copyRequested(int id)
    signal pinToggled(int id, bool newState)

    onEntryIdChanged: {
        d.clear();

        if (root.entryId >= 0) {
            d.loading = true;
            ClipboardManager.requestFullEntry(root.entryId);
        }
    }

    function formatTimestamp(ms: int): string {
        if (ms <= 0)
            return "";
        return new Date(ms).toLocaleString(Qt.locale(), "MMM d, hh:mm ap");
    }

    function formatSize(bytes: int): string {
        if (bytes < 1024)
            return bytes + " B";
        if (bytes < 1048576)
            return (bytes / 1024).toFixed(1) + " KB";
        return (bytes / 1048576).toFixed(1) + " MB";
    }

    Connections {
        target: ClipboardManager

        function onFullEntryReady(entry) {
            // Drop stale responses if user moved selection during fetch
            if (entry.id !== root.entryId)
                return;
            d.entryType = entry.type ?? "text";
            d.isImage = entry.type === "image";
            d.content = entry.content ?? "";
            d.sourceApp = entry.sourceApp ?? "";
            d.pinned = entry.pinned ?? false;
            d.sizeBytes = entry.sizeBytes ?? 0;
            d.timestamp = root.formatTimestamp(entry.timestamp ?? 0);
            d.fileName = entry.fileName ?? "";

            d.previewPath = entry.previewPath ?? "";

            d.loading = false;
        }
    }

    QtObject {
        id: d

        property bool loading: false
        property bool isImage: false
        property string previewPath: ""
        property string content: ""
        property string sourceApp: ""
        property string timestamp: ""
        property bool pinned: false
        property int sizeBytes: 0
        property string entryType: "text"
        property string fileName: ""

        function clear() {
            loading = false;
            isImage = false;
            previewPath = "";
            content = "";
            sourceApp = "";
            timestamp = "";
            pinned = false;
            sizeBytes = 0;
            entryType = "text";
            fileName = "";
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.entryId < 0

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: "content_paste"
            font.pixelSize: Appearance.fonts.size.extraLarge
            color: Colours.m3Colors.m3OnSurfaceVariant
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Select an entry to preview")
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }

    LoadingIndicator {
        anchors.centerIn: parent
        implicitWidth: 30
        implicitHeight: 30
        status: root.entryId >= 0 && d.loading
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        spacing: Appearance.spacing.large
        visible: root.entryId >= 0 && !d.loading

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.smaller

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledRect {
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: Appearance.rounding.small
                        color: Qt.alpha(d.isImage ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3SurfaceContainerHigh, 0.18)

                        Icon {
                            anchors.centerIn: parent
                            icon: d.isImage ? "image" : "assignment"
                            font.pixelSize: Appearance.fonts.size.large
                            color: d.isImage ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                        }
                    }

                    StyledText {
                        text: d.isImage ? qsTr("Image") : qsTr("Text")
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.Medium
                        color: Colours.m3Colors.m3OnSurface
                    }

                    StyledText {
                        visible: d.isImage && d.fileName.length > 0
                        Layout.maximumWidth: 220
                        Layout.fillWidth: false
                        text: d.fileName
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.normal
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }

                    StyledRect {
                        visible: d.sourceApp.length > 0
                        implicitWidth: srcLabel.implicitWidth + Appearance.padding.normal
                        implicitHeight: 18
                        radius: Appearance.rounding.small
                        color: Qt.alpha(Colours.m3Colors.m3SecondaryContainer, 0.8)

                        StyledText {
                            id: srcLabel

                            anchors.centerIn: parent
                            text: d.sourceApp
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSecondaryContainer
                        }
                    }
                }

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: d.timestamp
                        font.pixelSize: Appearance.fonts.size.small
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }

                    StyledText {
                        text: root.formatSize(d.sizeBytes)
                        font.pixelSize: Appearance.fonts.size.small
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                }
            }

            // Pin button
            StyledRect {
                implicitWidth: 32
                implicitHeight: 32
                radius: Appearance.rounding.small
                color: pinArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.18) : Qt.alpha(Colours.m3Colors.m3SurfaceContainerHigh, 0.5)

                Icon {
                    anchors.centerIn: parent
                    icon: d.pinned ? "keep" : "keep_off"
                    font.pixelSize: Appearance.fonts.size.large
                    color: d.pinned ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                }

                MArea {
                    id: pinArea

                    onClicked: root.pinToggled(root.entryId, !d.pinned)
                }
            }

            // Copy button
            StyledRect {
                implicitWidth: 80
                implicitHeight: 32
                radius: Appearance.rounding.small
                color: copyArea.containsMouse ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3Primary, 0.75)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    Icon {
                        icon: "content_copy"
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnPrimary
                    }
                    StyledText {
                        text: qsTr("Copy")
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.Medium
                        color: Colours.m3Colors.m3OnPrimary
                    }
                }

                MArea {
                    id: copyArea

                    onClicked: root.copyRequested(root.entryId)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
        }

        // Text preview
        ScrollView {
            id: textScroll

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !d.isImage
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageUp) {
                    contentItem.contentY = Math.max(0, contentItem.contentY - height); // qmllint disable
                    event.accepted = true;
                }
                if (event.key === Qt.Key_PageDown) {
                    contentItem.contentY = Math.min(contentItem.contentHeight - height, contentItem.contentY + height); // qmllint disable
                    event.accepted = true;
                }
                if (event.key === Qt.Key_Up) {
                    contentItem.contentY = Math.max(0, contentItem.contentY - 40); // qmllint disable
                    event.accepted = true;
                }
                if (event.key === Qt.Key_Down) {
                    contentItem.contentY = Math.min(contentItem.contentHeight - height, contentItem.contentY + 40); // qmllint disable
                    event.accepted = true;
                }
            }

            TextEdit {
                width: textScroll.width
                text: d.content
                readOnly: true
                selectByMouse: true
                selectByKeyboard: true
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText

                font.pixelSize: Appearance.fonts.size.medium
                font.family: Appearance.fonts.family.mono
                color: Colours.m3Colors.m3OnSurface

                selectionColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.35)
                selectedTextColor: Colours.m3Colors.m3OnSurface
                padding: Appearance.padding.small
            }
        }

        // Image preview
        ScrollView {
            id: imageScroll

            Layout.fillWidth: true
            Layout.fillHeight: true
            // When visible flips false the Image element is hidden and
            // Qt releases the decoded GPU texture.
            visible: d.isImage
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded

            Keys.onUpPressed: contentItem.contentY -= 40 // qmllint disable
            Keys.onDownPressed: contentItem.contentY += 40 // qmllint disable
            Keys.onLeftPressed: contentItem.contentX -= 40 // qmllint disable
            Keys.onRightPressed: contentItem.contentX += 40 // qmllint disable

            WheelHandler {
                id: imageZoom

                property real scale: 1.0
                acceptedModifiers: Qt.ControlModifier
                onWheel: event => {
                    const step = event.angleDelta.y / 120;
                    scale = Math.max(0.25, Math.min(4.0, scale + step * 0.15));
                }
            }

            Item {
                width: Math.max(imageScroll.width, img.paintedWidth * imageZoom.scale)
                height: Math.max(imageScroll.height, img.paintedHeight * imageZoom.scale)

                Image {
                    id: img

                    anchors.centerIn: parent
                    width: imageScroll.width * imageZoom.scale
                    height: imageScroll.height * imageZoom.scale
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true

                    source: d.previewPath.length > 0 ? ("file://" + d.previewPath) : ""
                    sourceSize: Qt.size(300, 300)

                    opacity: status === Image.Ready ? 1.0 : 0.0
                    Behavior on opacity {
                        NAnim {}
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: img.status === Image.Loading
                    text: qsTr("Loading…")
                    font.pixelSize: Appearance.fonts.size.medium
                    color: Colours.m3Colors.m3Secondary
                }
            }
        }
    }
}
