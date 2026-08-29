import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import Vast.Utils

import "../../../Base"

Rectangle {
    id: root

    property alias fileName: fileName.text
    property int fileSize: 0
    property var fileModified
    property string filePath: ""
    property bool isFolder: false
    property bool isSelected: false
    property int itemIndex: 0
    signal clicked
    signal doubleClicked

    property bool keyboardFocusable: true

    function requestKeyboardFocus() {
        root.forceActiveFocus();
    }

    Keys.onReturnPressed: event => {
        root.clicked();
        event.accepted = true;
    }

    Keys.onSpacePressed: event => {
        root.clicked();
        event.accepted = true;
    }

    implicitHeight: 48
    clip: true
    property color rowColorFrom
    property color rowColorTo
    property bool rowColorBlending: false
    property real rowColorBlendProgress: 1.0

    onRowColorBlendProgressChanged: {
        if (!rowColorBlending)
            return;
        if (rowColorBlendProgress >= 1) {
            color = rowColorTo;
            rowColorBlending = false;
        } else if (rowColorBlendProgress > 0) {
            color = ColorUtils.blendColors(rowColorFrom, rowColorTo, rowColorBlendProgress);
        }
    }

    NAnim {
        id: rowColorAnim
        target: root
        property: "rowColorBlendProgress"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.small
    }

    function getFileExtension(name, folder) {
        if (folder)
            return qsTr("Folder");
        var dot = name.lastIndexOf(".");
        return dot >= 0 ? name.substring(dot + 1).toUpperCase() + " " + qsTr("file") : qsTr("File");
    }

    function formatSize(bytes) {
        if (bytes < 1024)
            return bytes + " " + qsTr("B");
        if (bytes < 1048576)
            return (bytes / 1024).toFixed(1) + " " + qsTr("KiB");
        if (bytes < 1073741824)
            return (bytes / 1048576).toFixed(1) + " " + qsTr("MiB");
        return (bytes / 1073741824).toFixed(1) + " " + qsTr("GiB");
    }

    property color target: root.isSelected ? Qt.alpha(Colours.m3Colors.m3Primary, 0.3) : "transparent"
    onTargetChanged: {
        rowColorAnim.stop();
        rowColorFrom = root.color;
        rowColorTo = target;
        rowColorBlending = true;
        rowColorBlendProgress = 0.0;
        rowColorAnim.start();
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.m3Colors.m3OnSurface
        opacity: !root.isSelected && (root.itemIndex % 2 !== 0) ? 0.03 : 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Colours.m3Colors.m3Primary
        border.width: 2
        visible: root.activeFocus

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.normal
        }
        spacing: Appearance.spacing.small

        Icon {
            id: iconItem
            property color iconColorFrom
            property color iconColorTo
            property bool iconColorBlending: false
            property real iconColorBlendProgress: 1.0

            onIconColorBlendProgressChanged: {
                if (!iconColorBlending)
                    return;
                if (iconColorBlendProgress >= 1) {
                    color = iconColorTo;
                    iconColorBlending = false;
                } else if (iconColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(iconColorFrom, iconColorTo, iconColorBlendProgress);
                }
            }

            NAnim {
                id: iconColorAnim
                target: iconItem
                property: "iconColorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : (root.isFolder ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant)
            onTargetChanged: {
                iconColorAnim.stop();
                iconColorFrom = iconItem.color;
                iconColorTo = target;
                iconColorBlending = true;
                iconColorBlendProgress = 0.0;
                iconColorAnim.start();
            }

            icon: root.isFolder ? "folder" : "description"
            font.pixelSize: Appearance.fonts.size.large
            Layout.preferredWidth: 32
        }

        StyledText {
            id: fileName
            property color nameColorFrom
            property color nameColorTo
            property bool nameColorBlending: false
            property real nameColorBlendProgress: 1.0

            onNameColorBlendProgressChanged: {
                if (!nameColorBlending)
                    return;
                if (nameColorBlendProgress >= 1) {
                    color = nameColorTo;
                    nameColorBlending = false;
                } else if (nameColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(nameColorFrom, nameColorTo, nameColorBlendProgress);
                }
            }

            NAnim {
                id: nameColorAnim
                target: fileName
                property: "nameColorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : root.fileName.startsWith(".") ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface
            onTargetChanged: {
                nameColorAnim.stop();
                nameColorFrom = fileName.color;
                nameColorTo = target;
                nameColorBlending = true;
                nameColorBlendProgress = 0.0;
                nameColorAnim.start();
            }

            Layout.fillWidth: true
            text: ""
            font.pixelSize: Appearance.fonts.size.normal
            elide: Text.ElideRight
            leftPadding: 2
        }

        StyledText {
            id: sizeText
            property color sizeColorFrom
            property color sizeColorTo
            property bool sizeColorBlending: false
            property real sizeColorBlendProgress: 1.0

            onSizeColorBlendProgressChanged: {
                if (!sizeColorBlending)
                    return;
                if (sizeColorBlendProgress >= 1) {
                    color = sizeColorTo;
                    sizeColorBlending = false;
                } else if (sizeColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(sizeColorFrom, sizeColorTo, sizeColorBlendProgress);
                }
            }

            NAnim {
                id: sizeColorAnim
                target: sizeText
                property: "sizeColorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                sizeColorAnim.stop();
                sizeColorFrom = sizeText.color;
                sizeColorTo = target;
                sizeColorBlending = true;
                sizeColorBlendProgress = 0.0;
                sizeColorAnim.start();
            }

            text: root.isFolder ? "" : root.formatSize(root.fileSize)
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 76
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            id: extensionText
            property color extensionColorFrom
            property color extensionColorTo
            property bool extensionColorBlending: false
            property real extensionColorBlendProgress: 1.0

            onExtensionColorBlendProgressChanged: {
                if (!extensionColorBlending)
                    return;
                if (extensionColorBlendProgress >= 1) {
                    color = extensionColorTo;
                    extensionColorBlending = false;
                } else if (extensionColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(extensionColorFrom, extensionColorTo, extensionColorBlendProgress);
                }
            }

            NAnim {
                id: extensionColorAnim
                target: extensionText
                property: "extensionColorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                extensionColorAnim.stop();
                extensionColorFrom = extensionText.color;
                extensionColorTo = target;
                extensionColorBlending = true;
                extensionColorBlendProgress = 0.0;
                extensionColorAnim.start();
            }

            text: root.getFileExtension(root.fileName, root.isFolder)
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 90
            leftPadding: 10
            elide: Text.ElideRight
        }

        StyledText {
            id: dateText
            property color dateColorFrom
            property color dateColorTo
            property bool dateColorBlending: false
            property real dateColorBlendProgress: 1.0

            onDateColorBlendProgressChanged: {
                if (!dateColorBlending)
                    return;
                if (dateColorBlendProgress >= 1) {
                    color = dateColorTo;
                    dateColorBlending = false;
                } else if (dateColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(dateColorFrom, dateColorTo, dateColorBlendProgress);
                }
            }

            NAnim {
                id: dateColorAnim
                target: dateText
                property: "dateColorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                dateColorAnim.stop();
                dateColorFrom = dateText.color;
                dateColorTo = target;
                dateColorBlending = true;
                dateColorBlendProgress = 0.0;
                dateColorAnim.start();
            }

            text: Qt.formatDateTime(root.fileModified, "yyyy-MM-dd hh:mm")
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 110
            leftPadding: 6
        }
    }

    MArea {
        layerRadius: root.radius
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}
