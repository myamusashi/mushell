pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Button
import qs.Components.Dialog.FileDialog
import qs.Core.Configs
import qs.Core.Utils
import qs.Greeter
import qs.Services

import "../Components"

SettingsPageBase {
    id: page
    pageTitle: qsTr("Greeter")

    property bool videoUploadMode: false

    SettingsCard {
        title: qsTr("Greeter Wallpaper")
        Layout.fillWidth: true

        SettingRow {
            label: qsTr("Wallpaper type:")

            SplitButton {
                id: wallpaperButton

                readonly property int selectedIndex: Configs.greeterConfig.useVideoWallpaper ? 0 : 1

                model: [
                    {
                        display: "Video"
                    },
                    {
                        display: "Static"
                    }
                ]

                textRole: "display"
                icon.name: "wallpaper"
                text: model[selectedIndex] ? model[selectedIndex].display : ""
                currentIndex: selectedIndex
            }
        }

        SettingRow {
            label: qsTr("Upload wallpaper:")

            ExtendedFloatingButton {
                text: qsTr("Upload static")
                icon.name: "image"
                onClicked: {
                    page.videoUploadMode = false;
                    wallpaperDialog.openFileDialog();
                }
            }

            ExtendedFloatingButton {
                text: qsTr("Upload video")
                icon.name: "video_file"
                onClicked: {
                    page.videoUploadMode = true;
                    wallpaperDialog.openFileDialog();
                }
            }

            FileDialog {
                id: wallpaperDialog

                nameFilters: page.videoUploadMode ? ["*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi"] : ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                onFileSelected: path => {
                    if (page.videoUploadMode)
                        Configs.uploadVideo(path);
                    else
                        Configs.uploadStatic(path);
                }
            }
        }

        SettingRow {
            label: qsTr("Preview:")

            ClippingRectangle {
                Layout.preferredWidth: 320
                Layout.preferredHeight: 180
                radius: Appearance.rounding.normal

                Image {
                    anchors.fill: parent
                    source: Configs.greeterConfig.useVideoWallpaper ? "file://" + Paths.cacheDir + "/vast-shell/greeter-wallpaper-" + Qt.md5(Configs.greeterConfig.videoWallpaper) + ".png?v=" + Configs.thumbnailVersion : "file://" + Configs.greeterConfig.staticWallpaper + "?v=" + Configs.thumbnailVersion
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready

                    Rectangle {
                        anchors.fill: parent
                        color: Colours.m3Colors.m3SurfaceContainerHigh
                        visible: !parent.visible

                        Icon {
                            anchors.centerIn: parent
                            icon: "image"
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.extraLarge
                        }

                        StyledText {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 28
                            text: qsTr("Preview not available yet")
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.normal
                        }
                    }
                }
            }
        }
    }
}
