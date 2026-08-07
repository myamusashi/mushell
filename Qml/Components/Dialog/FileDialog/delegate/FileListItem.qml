import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

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
    property color c0From
    property color c0To
    property bool c0Active: false
    property real c0Blend: 1.0

    onC0BlendChanged: {
        if (!c0Active)
            return;
        if (c0Blend >= 1) {
            color = c0To;
            c0Active = false;
        } else if (c0Blend > 0) {
            color = Colours.blendColors(c0From, c0To, c0Blend);
        }
    }

    NAnim {
        id: c0Anim
        target: root
        property: "c0Blend"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.small
    }

    property color target: root.isSelected ? Qt.alpha(Colours.m3Colors.m3Primary, 0.3) : "transparent"
    onTargetChanged: {
        c0Anim.stop();
        c0From = root.color;
        c0To = target;
        c0Active = true;
        c0Blend = 0.0;
        c0Anim.start();
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
            property color c1From
            property color c1To
            property bool c1Active: false
            property real c1Blend: 1.0

            onC1BlendChanged: {
                if (!c1Active)
                    return;
                if (c1Blend >= 1) {
                    color = c1To;
                    c1Active = false;
                } else if (c1Blend > 0) {
                    color = Colours.blendColors(c1From, c1To, c1Blend);
                }
            }

            NAnim {
                id: c1Anim
                target: iconItem
                property: "c1Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : (root.isFolder ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant)
            onTargetChanged: {
                c1Anim.stop();
                c1From = iconItem.color;
                c1To = target;
                c1Active = true;
                c1Blend = 0.0;
                c1Anim.start();
            }

            icon: root.isFolder ? "folder" : "description"
            font.pixelSize: Appearance.fonts.size.large
            Layout.preferredWidth: 32
        }

        StyledText {
            id: fileName
            property color c2From
            property color c2To
            property bool c2Active: false
            property real c2Blend: 1.0

            onC2BlendChanged: {
                if (!c2Active)
                    return;
                if (c2Blend >= 1) {
                    color = c2To;
                    c2Active = false;
                } else if (c2Blend > 0) {
                    color = Colours.blendColors(c2From, c2To, c2Blend);
                }
            }

            NAnim {
                id: c2Anim
                target: fileName
                property: "c2Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : root.fileName.startsWith(".") ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface
            onTargetChanged: {
                c2Anim.stop();
                c2From = fileName.color;
                c2To = target;
                c2Active = true;
                c2Blend = 0.0;
                c2Anim.start();
            }

            Layout.fillWidth: true
            text: ""
            font.pixelSize: Appearance.fonts.size.normal
            elide: Text.ElideRight
            leftPadding: 2
        }

        StyledText {
            id: sizeText
            property color c3From
            property color c3To
            property bool c3Active: false
            property real c3Blend: 1.0

            onC3BlendChanged: {
                if (!c3Active)
                    return;
                if (c3Blend >= 1) {
                    color = c3To;
                    c3Active = false;
                } else if (c3Blend > 0) {
                    color = Colours.blendColors(c3From, c3To, c3Blend);
                }
            }

            NAnim {
                id: c3Anim
                target: sizeText
                property: "c3Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                c3Anim.stop();
                c3From = sizeText.color;
                c3To = target;
                c3Active = true;
                c3Blend = 0.0;
                c3Anim.start();
            }

            text: root.isFolder ? "" : root.formatSize(root.fileSize)
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 76
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            id: extText
            property color c4From
            property color c4To
            property bool c4Active: false
            property real c4Blend: 1.0

            onC4BlendChanged: {
                if (!c4Active)
                    return;
                if (c4Blend >= 1) {
                    color = c4To;
                    c4Active = false;
                } else if (c4Blend > 0) {
                    color = Colours.blendColors(c4From, c4To, c4Blend);
                }
            }

            NAnim {
                id: c4Anim
                target: extText
                property: "c4Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                c4Anim.stop();
                c4From = extText.color;
                c4To = target;
                c4Active = true;
                c4Blend = 0.0;
                c4Anim.start();
            }

            text: root.getFileExtension(root.fileName, root.isFolder)
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 90
            leftPadding: 10
            elide: Text.ElideRight
        }

        StyledText {
            id: dateText
            property color c5From
            property color c5To
            property bool c5Active: false
            property real c5Blend: 1.0

            onC5BlendChanged: {
                if (!c5Active)
                    return;
                if (c5Blend >= 1) {
                    color = c5To;
                    c5Active = false;
                } else if (c5Blend > 0) {
                    color = Colours.blendColors(c5From, c5To, c5Blend);
                }
            }

            NAnim {
                id: c5Anim
                target: dateText
                property: "c5Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                c5Anim.stop();
                c5From = dateText.color;
                c5To = target;
                c5Active = true;
                c5Blend = 0.0;
                c5Anim.start();
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
