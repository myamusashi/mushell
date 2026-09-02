import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Button
import qs.Services.CaptureScreenVideo

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Screen Recorder")

    SettingsCard {
        title: qsTr("Recording")

        GridLayout {
            columns: 2

            SettingRow {
                label: qsTr("Frame Rate")
                description: qsTr("Target frames per second for screen recordings.")
                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.maxFps)

                    textRole: "display"
                    model: [
                        {
                            display: "30 FPS",
                            value: 30
                        },
                        {
                            display: "60 FPS",
                            value: 60
                        },
                        {
                            display: "120 FPS",
                            value: 120
                        }
                    ]
                    currentIndex: selectedIndex
                    text: model[selectedIndex]?.display ?? ""
                    icon.name: "autofps_select"

                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.maxFps = model[index].value;
                        CaptureScreenVideo.maxFps = model[index].value;
                    }
                }
            }

            SettingRow {
                label: qsTr("Bitrate")
                description: qsTr("Bitrate limit for recordings. Higher values give sharper video but larger files.")
                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.bitrate)

                    textRole: "display"
                    model: [
                        {
                            display: "1 MB",
                            value: "1 MB"
                        },
                        {
                            display: "5 MB",
                            value: "5 MB"
                        },
                        {
                            display: "10 MB",
                            value: "10 MB"
                        },
                        {
                            display: "20 MB",
                            value: "20 MB"
                        }
                    ]
                    currentIndex: selectedIndex
                    text: model[selectedIndex]?.display ?? ""
                    icon.name: "shutter_speed"

                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.bitrate = model[index].value;
                        CaptureScreenVideo.bitrate = model[index].value;
                    }
                }
            }

            SettingRow {
                label: qsTr("Video Codec")
                description: qsTr("Encoder for the video stream.")
                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.videoCodec)

                    textRole: "display"
                    model: [
                        {
                            display: "Auto",
                            value: ""
                        },
                        {
                            display: "AVC",
                            value: "avc"
                        },
                        {
                            display: "HEVC",
                            value: "hevc"
                        },
                        {
                            display: "VP8",
                            value: "vp8"
                        },
                        {
                            display: "VP9",
                            value: "vp9"
                        },
                        {
                            display: "AV1",
                            value: "av1"
                        }
                    ]
                    currentIndex: selectedIndex
                    text: model[selectedIndex]?.display ?? ""
                    icon.name: "hd"

                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.videoCodec = model[index].value;
                        CaptureScreenVideo.videoCodec = model[index].value;
                    }
                }
            }

            SettingRow {
                label: qsTr("Audio Codec")
                description: qsTr("Encoder for the audio stream.")
                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.audioCodec)

                    textRole: "display"
                    model: [
                        {
                            display: "Auto",
                            value: ""
                        },
                        {
                            display: "AAC",
                            value: "aac"
                        },
                        {
                            display: "MP3",
                            value: "mp3"
                        },
                        {
                            display: "FLAC",
                            value: "flac"
                        },
                        {
                            display: "Opus",
                            value: "opus"
                        }
                    ]
                    currentIndex: selectedIndex
                    text: model[selectedIndex]?.display ?? ""
                    icon.name: "hd"

                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.audioCodec = model[index].value;
                        CaptureScreenVideo.audioCodec = model[index].value;
                    }
                }
            }

            SettingRow {
                label: qsTr("Power Mode")
                description: qsTr("Power profile for recording. Low saves battery, Normal favors quality.")
                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.lowPower)

                    textRole: "display"
                    model: [
                        {
                            display: qsTr("Auto"),
                            value: "auto"
                        },
                        {
                            display: qsTr("Low"),
                            value: "on"
                        },
                        {
                            display: qsTr("Normal"),
                            value: "off"
                        }
                    ]
                    currentIndex: selectedIndex
                    text: model[selectedIndex]?.display ?? ""
                    icon.name: "power"

                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.lowPower = model[index].value;
                        CaptureScreenVideo.lowPower = model[index].value;
                    }
                }
            }
        }

        SettingRow {
            label: qsTr("Show Cursor")
            description: qsTr("Include the mouse cursor in the recording.")
            StyledSwitch {
                checked: Configs.captureScreenVideo.showCursor
                onCheckedChanged: {
                    Configs.captureScreenVideo.showCursor = checked;
                    CaptureScreenVideo.showCursor = checked;
                }
            }
        }

        SettingRow {
            label: qsTr("Replay Buffer")
            StyledSwitch {
                checked: Configs.captureScreenVideo.historyMode
                onCheckedChanged: {
                    Configs.captureScreenVideo.historyMode = checked;
                    CaptureScreenVideo.historyMode = checked;
                }
            }
        }
    }
}
