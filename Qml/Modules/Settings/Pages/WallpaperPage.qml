pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Components.Menu
import qs.Components.Dialog.FileDialog

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Wallpaper Engine")

    DepthWallpaperSection {
        Layout.fillWidth: true
    }

    SettingsCard {
        title: qsTr("Pick Wallpaper File")
        Layout.fillWidth: true

        SettingRow {
            label: qsTr("Select a wallpaper image file:")

            StyledButton {
                icon.name: "image"
                text: qsTr("Browse\u2026")
                onClicked: pickWallpaperDialog.openFileDialog()
            }

            FileDialog {
                id: pickWallpaperDialog
                nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.svg", "*.webp"]
                onFileSelected: path => Quickshell.execDetached({
                        command: ["vastctl", "wallpaper", "set", path]
                    })
            }
        }
    }

    SettingsCard {
        title: qsTr("Wallpaper Picker")
        visible: WallpaperFileModels.wallpaperList.length > 0
        Layout.fillWidth: true

        StyledTextInput {
            id: searchField
            Layout.fillWidth: true
            placeHolderText: qsTr("Search wallpapers\u2026")
            toggleButtonVisible: false
            onTextChanged: {
                WallpaperFileModels.searchQuery = text;
                searchDebounceTimer.restart();
            }
        }

        Timer {
            id: searchDebounceTimer
            interval: 300
            onTriggered: WallpaperFileModels.debouncedSearchQuery = searchField.text
        }

        PathView {
            id: wallpaperPath
            Layout.fillWidth: true
            Layout.minimumHeight: 160
            clip: true
            pathItemCount: 5
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            cacheItemCount: pathItemCount + 2

            model: ScriptModel {
                values: WallpaperFileModels.filteredWallpaperList
            }

            path: Path {
                startX: 0
                startY: wallpaperPath.height / 2

                PathLine {
                    x: wallpaperPath.width
                    y: wallpaperPath.height / 2
                }
            }

            delegate: Item {
                id: delegateRoot

                required property var modelData
                readonly property real itemWidth: wallpaperPath.width / wallpaperPath.pathItemCount

                implicitWidth: itemWidth
                implicitHeight: itemWidth * 0.65

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    border.color: delegateRoot.modelData === WallpaperFileModels.currentWallpaper ? Colours.m3Colors.m3Primary : "transparent"
                    border.width: delegateRoot.modelData === WallpaperFileModels.currentWallpaper ? 2 : 0

                    Image {
                        anchors.fill: parent
                        anchors.bottomMargin: fileNameText.implicitHeight + 4
                        source: (width > 0 && height > 0) ? delegateRoot.modelData : ""
                        sourceSize: Qt.size(150, 150)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.15)
                        visible: delegateRoot.modelData === WallpaperFileModels.currentWallpaper
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: fileNameText.implicitHeight + 4
                        color: "transparent"

                        StyledText {
                            id: fileNameText
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 2
                            }
                            text: delegateRoot.modelData.split('/').pop()
                            font.pixelSize: Appearance.fonts.size.small
                            color: "white"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached({
                            command: ["vastctl", "wallpaper", "set", delegateRoot.modelData]
                        })
                    }
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Image Sourcing")
        Layout.fillWidth: true

        SettingRow {
            label: qsTr("Enable Wallpaper:")

            StyledSwitch {
                checked: Configs.wallpaper.enabledWallpaper
                onCheckedChanged: Configs.wallpaper.enabledWallpaper = checked
            }
        }

        SettingRow {
            label: qsTr("Wallpaper Directory Path:")

            StyledTextInput {
                id: wallpaperDirField
                text: Configs.wallpaper.wallpaperDir
                onTextChanged: Configs.wallpaper.wallpaperDir = text
                implicitWidth: 350
                toggleButtonVisible: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wallpaperDirField.forceActiveFocus();
                        fileDialog.openFileDialog();
                    }
                }
            }

            FileDialog {
                id: fileDialog
                foldersOnly: true
                selectFolder: true
                showHidden: true
                onFileSelected: path => Configs.wallpaper.wallpaperDir = path
            }
        }

        SettingRow {
            label: qsTr("Loaded Wallpaper Count:")

            StyledSlide {
                from: 1
                to: 10
                stepSize: 1
                snapEnabled: true
                showValuePopup: true
                value: Configs.wallpaper.visibleWallpaper
                onMoved: Configs.wallpaper.visibleWallpaper = value
                Layout.preferredWidth: 200
            }
        }
    }

    SettingsCard {
        title: qsTr("Transitions & Performance")
        Layout.fillWidth: true

        SettingRow {
            label: qsTr("Transition Animation Mode:")

            DropdownField {
                model: [
                    {
                        display: "none"
                    },
                    {
                        display: "random"
                    },
                    {
                        display: "fade"
                    },
                    {
                        display: "wipedown"
                    },
                    {
                        display: "circle"
                    },
                    {
                        display: "dissolve"
                    },
                    {
                        display: "splitH"
                    },
                    {
                        display: "slideup"
                    },
                    {
                        display: "pixelate"
                    },
                    {
                        display: "diagonal"
                    },
                    {
                        display: "box"
                    },
                    {
                        display: "roll"
                    },
                    {
                        display: "hexTile"
                    },
                ]
                Layout.preferredWidth: 200
                currentIndex: -1
                placeholderText: Configs.wallpaper.transition
                isItemActive: (md, _) => md.display === Configs.wallpaper.transition
                onActivated: index => Configs.wallpaper.transition = model[index].display
            }
        }

        SettingRow {
            label: qsTr("Transition Low Performance Priority:")

            StyledSwitch {
                checked: Configs.wallpaper.transitionLowPerfMode
                onCheckedChanged: Configs.wallpaper.transitionLowPerfMode = checked
            }
        }

        SettingRow {
            label: qsTr("Transition Duration (ms):")

            StyledSlide {
                from: 100
                to: 2000
                stepSize: 50
                value: Configs.wallpaper.transitionDuration
                onMoved: Configs.wallpaper.transitionDuration = value
                Layout.preferredWidth: 200
            }
        }
    }
}
