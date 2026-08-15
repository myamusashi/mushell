pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Core.Configs
import qs.Services
import qs.Components.Menu

import "../../../Base"
import "../delegate"

ColumnLayout {
    id: root

    required property var model

    property bool folderHidden: false
    property bool selectFolder: false
    property int currentIndex: -1
    property bool hasSelection: currentIndex >= 0
    property string selectedFileName: hasSelection && currentIndex < visualModel.items.count ? visualModel.items.get(currentIndex).model.fileName : ""
    property string currentFilePath: hasSelection && currentIndex < visualModel.items.count ? visualModel.items.get(currentIndex).model.filePath : ""
    property bool currentIsFolder: hasSelection && currentIndex < visualModel.items.count ? visualModel.items.get(currentIndex).model.isFolder : false

    property bool currentIsImage: hasSelection && !currentIsFolder && /\.(png|jpg|jpeg|gif|bmp|svg|webp)$/i.test(selectedFileName)

    signal showHiddenToggled(bool hidden)
    signal folderDoubleClicked(string path)
    signal fileDoubleClicked(string path)
    signal selectionChanged(string fileName, string filePath, int fileSize, var fileModified, bool isImage)

    spacing: 0
    onFolderHiddenChanged: root.showHiddenToggled(folderHidden)

    function clearSelection() {
        currentIndex = -1;
        fileList.currentIndex = -1;
    }

    DelegateModel {
        id: visualModel

        model: root.model
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 40
        color: Colours.m3Colors.m3SurfaceContainer

        ContextMenu {
            id: contextMenu

            showScrollBar: false

            MenuItem {
                label: qsTr("Show hidden")
                selected: root.folderHidden
                onTriggered: root.folderHidden = !root.folderHidden
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            implicitWidth: parent.width
            implicitHeight: 1
            color: Colours.m3Colors.m3OutlineVariant
            opacity: 0.4
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.margin.small
                rightMargin: Appearance.margin.normal
            }
            spacing: Appearance.spacing.small

            Item {
                Layout.preferredWidth: 32
            }

            StyledText {
                text: qsTr("Name")
                font.pixelSize: Appearance.fonts.size.small
                font.bold: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.fillWidth: true
                leftPadding: Appearance.padding.small
            }
            StyledText {
                text: qsTr("Size")
                font.pixelSize: Appearance.fonts.size.small
                font.bold: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 76
                horizontalAlignment: Text.AlignRight
            }
            StyledText {
                text: qsTr("Type")
                font.pixelSize: Appearance.fonts.size.small
                font.bold: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 90
                leftPadding: 10
            }
            StyledText {
                text: qsTr("Modified")
                font.pixelSize: Appearance.fonts.size.small
                font.bold: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: 110
                leftPadding: 6
            }
        }
    }

    ListView {
        id: fileList

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.model
        spacing: 0
        currentIndex: root.currentIndex

        MouseArea {
            id: fileListMouseArea

            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: mouse => {
                contextMenu.parent = fileListMouseArea;
                contextMenu.openAt(mouse.x, mouse.y);
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: vScroll

            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 6
                implicitHeight: 48
                radius: width / 2
                color: Colours.m3Colors.m3OnSurfaceVariant
                opacity: vScroll.pressed ? 0.7 : vScroll.hovered ? 0.5 : 0.3
                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }
            background: Rectangle {
                color: "transparent"
            }
        }

        add: Transition {
            NAnim {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.standardDecel
            }
            NAnim {
                property: "y"
                from: 12
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
        }
        displaced: Transition {
            NAnim {
                property: "y"
            }
        }

        delegate: FileListItem {
            required property var model
            required property int index

            implicitWidth: fileList.width
            fileName: model.fileName
            fileSize: model.fileSize
            fileModified: model.fileModified
            filePath: model.filePath
            isFolder: model.fileIsDir
            isSelected: fileList.currentIndex === index
            itemIndex: index

            onClicked: {
                fileList.currentIndex = index;
                root.currentIndex = index;
                var img = !isFolder && /\.(png|jpg|jpeg|gif|bmp|svg|webp)$/i.test(fileName);
                if (root.selectFolder) {
                    root.selectionChanged(fileName, filePath, fileSize, fileModified, false);
                } else {
                    root.selectionChanged(isFolder ? "" : fileName, filePath, fileSize, fileModified, img);
                }
            }
            onDoubleClicked: {
                if (isFolder)
                    root.folderDoubleClicked(filePath);
                else if (!root.selectFolder)
                    root.fileDoubleClicked(filePath);
            }
        }
    }
}
