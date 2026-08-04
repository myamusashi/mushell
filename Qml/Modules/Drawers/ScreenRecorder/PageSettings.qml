pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services.ScreenRecorder

StyledRect {
    id: root

    signal goBack

    color: "transparent"
    radius: 0
    clip: true

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.small

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
            color: backButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent"
            radius: Appearance.rounding.small

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.small
                spacing: Appearance.spacing.small

                Icon {
                    type: Icon.Material
                    icon: "arrow_back"
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                }

                StyledText {
                    text: qsTr("Settings")
                    color: Colours.m3Colors.m3OnSurface
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            MArea {
                id: backButtonMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.goBack()
            }
        }

        Flickable {
            id: flickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: settingsColumn.implicitHeight

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: settingsColumn

                width: flickable.width
                spacing: Appearance.spacing.normal

                SettingSection {
                    label: qsTr("Frame Rate")
                    model: [
                        {
                            text: "30 FPS",
                            value: 30
                        },
                        {
                            text: "60 FPS",
                            value: 60
                        },
                        {
                            text: "120 FPS",
                            value: 120
                        }
                    ]
                    selectedValue: ScreenRecorder.maxFps
                    onSelected: value => ScreenRecorder.maxFps = value
                }

                SettingSection {
                    label: qsTr("Bitrate")
                    model: [
                        {
                            text: "1 MB",
                            value: "1 MB"
                        },
                        {
                            text: "5 MB",
                            value: "5 MB"
                        },
                        {
                            text: "10 MB",
                            value: "10 MB"
                        },
                        {
                            text: "20 MB",
                            value: "20 MB"
                        }
                    ]
                    selectedValue: ScreenRecorder.bitrate
                    onSelected: value => ScreenRecorder.bitrate = value
                }

                SettingSection {
                    label: qsTr("Video Codec")
                    model: [
                        {
                            text: "Auto",
                            value: ""
                        },
                        {
                            text: "AVC",
                            value: "avc"
                        },
                        {
                            text: "HEVC",
                            value: "hevc"
                        },
                        {
                            text: "VP8",
                            value: "vp8"
                        },
                        {
                            text: "VP9",
                            value: "vp9"
                        },
                        {
                            text: "AV1",
                            value: "av1"
                        }
                    ]
                    selectedValue: ScreenRecorder.videoCodec
                    onSelected: value => ScreenRecorder.videoCodec = value
                }

                SettingSection {
                    label: qsTr("Audio Codec")
                    model: [
                        {
                            text: "Auto",
                            value: ""
                        },
                        {
                            text: "AAC",
                            value: "aac"
                        },
                        {
                            text: "MP3",
                            value: "mp3"
                        },
                        {
                            text: "FLAC",
                            value: "flac"
                        },
                        {
                            text: "Opus",
                            value: "opus"
                        }
                    ]
                    selectedValue: ScreenRecorder.audioCodec
                    onSelected: value => ScreenRecorder.audioCodec = value
                }

                SettingSection {
                    label: qsTr("Power Mode")
                    model: [
                        {
                            text: qsTr("Auto"),
                            value: "auto"
                        },
                        {
                            text: qsTr("Low"),
                            value: "on"
                        },
                        {
                            text: qsTr("Normal"),
                            value: "off"
                        }
                    ]
                    selectedValue: ScreenRecorder.lowPower
                    onSelected: value => ScreenRecorder.lowPower = value
                }

                SettingSection {
                    label: qsTr("Toggles")
                    model: [
                        {
                            text: qsTr("Show Cursor"),
                            value: "cursor"
                        },
                        {
                            text: qsTr("Replay Buffer"),
                            value: "history"
                        }
                    ]
                    selectedValue: ""
                    extraActive: item => {
                        switch (item.value) {
                        case "cursor":
                            return ScreenRecorder.showCursor;
                        case "history":
                            return ScreenRecorder.historyMode;
                        default:
                            return false;
                        }
                    }
                    onSelected: value => {
                        switch (value) {
                        case "cursor":
                            ScreenRecorder.showCursor = !ScreenRecorder.showCursor;
                            break;
                        case "history":
                            ScreenRecorder.historyMode = !ScreenRecorder.historyMode;
                            break;
                        }
                    }
                }
            }
        }
    }

    component SettingSection: ColumnLayout {
        id: section

        spacing: Appearance.spacing.small

        required property string label
        required property var model
        required property var selectedValue
        property var extraActive: null
        signal selected(var value)

        StyledText {
            text: section.label
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Appearance.spacing.small
            rowSpacing: Appearance.spacing.small

            Repeater {
                model: section.model

                delegate: StyledRect {
                    id: optionDelegate

                    required property var modelData

                    readonly property var value: optionDelegate.modelData.value ?? optionDelegate.modelData
                    readonly property bool active: section.extraActive ? section.extraActive(modelData) : section.selectedValue === value // qmllint disable

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: optionDelegate.active ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (pillMouse.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                    radius: Appearance.rounding.small

                    StyledText {
                        anchors.centerIn: parent
                        text: optionDelegate.modelData.text ?? optionDelegate.modelData
                        color: optionDelegate.active ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: optionDelegate.active ? Font.DemiBold : Font.Normal
                    }

                    MArea {
                        id: pillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: section.selected(optionDelegate.value)
                    }
                }
            }
        }
    }
}
