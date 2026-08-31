import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Button
import qs.Components.Feedback

import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: Appearance.spacing.large

        SettingsCard {
            title: qsTr("Depth Wallpaper")

            SettingRow {
                label: qsTr("Enable Depth Wallpaper")
                description: qsTr("Enable depth effect (Apple like).")

                StyledSwitch {
                    checked: Configs.wallpaper.depthWallpaperEnabled
                    onCheckedChanged: DepthWallpaperController.onToggle(checked)
                }
            }

            SettingRow {
                label: qsTr("Auto-process on wallpaper change:")
                description: qsTr("Automatically regenerate the depth map whenever the wallpaper changes.")

                StyledSwitch {
                    checked: Configs.wallpaper.autoProcessedDepthWallpaper
                    onCheckedChanged: Configs.wallpaper.autoProcessedDepthWallpaper = checked
                }
            }

            ExtendedFloatingButton {
                text: qsTr("Re-generate")
                icon.name: "refresh"
                implicitHeight: 36
                visible: Configs.wallpaper.depthWallpaperEnabled && DepthWallpaperController.state !== "processing"
                enabled: DepthWallpaperController.state !== "processing"
                onClicked: DepthWallpaperController.runRembg()
            }

            StyledText {
                text: {
                    switch (DepthWallpaperController.state) {
                    case "processing":
                        return qsTr("Generating depth map\u2026");
                    case "done":
                        return qsTr("Depth wallpaper ready");
                    case "error":
                        return DepthWallpaperController.errorMessage;
                    default:
                        return "";
                    }
                }
                font.pixelSize: Appearance.fonts.size.medium
                color: DepthWallpaperController.state === "error" ? Colours.m3Colors.m3Error : DepthWallpaperController.state === "done" ? Colours.m3Colors.m3Green : Colours.m3Colors.m3OnSurfaceVariant
                visible: text !== ""
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                Rectangle {
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 120
                    radius: Appearance.rounding.small
                    color: Colours.m3Colors.m3SurfaceContainerHigh

                    Image {
                        anchors.fill: parent
                        source: Paths.currentWallpaper
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    StyledText {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                            margins: Appearance.margin.small
                        }
                        text: qsTr("Source")
                        font.pixelSize: Appearance.fonts.size.small
                        color: Colours.m3Colors.m3OnSurface
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 120
                    radius: Appearance.rounding.small
                    color: Colours.m3Colors.m3SurfaceContainerHigh

                    Image {
                        anchors.fill: parent
                        source: DepthWallpaperController.state === "done" ? "file://" + DepthWallpaperController.fgPath : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: source !== ""
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHigh, 0.7)
                        visible: DepthWallpaperController.state === "processing"

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            LoadingIndicator {
                                Layout.alignment: Qt.AlignCenter
                                implicitWidth: 24
                                implicitHeight: 24
                                status: DepthWallpaperController.state === "processing"
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignCenter
                                text: qsTr("Loading")
                                font.pixelSize: Appearance.fonts.size.medium
                                color: Colours.m3Colors.m3Primary
                            }
                        }
                    }

                    StyledText {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                            margins: Appearance.margin.small
                        }
                        text: {
                            switch (DepthWallpaperController.state) {
                            case "processing":
                                return qsTr("Processing");
                            case "done":
                                return qsTr("Foreground");
                            case "error":
                                return qsTr("Error");
                            default:
                                return qsTr("Not generated");
                            }
                        }
                        font.pixelSize: Appearance.fonts.size.small
                        color: Colours.m3Colors.m3OnSurface
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
