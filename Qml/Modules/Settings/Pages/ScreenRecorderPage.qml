import QtQuick

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Button
import qs.Services.ScreenRecorder

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Screen Recorder")

    SettingsCard {
        title: qsTr("Recording")

        SettingRow {
            label: qsTr("Frame Rate")
            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.screenRecorder.maxFps)

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

                onMenuItemActivated: index => {
                    Configs.screenRecorder.maxFps = model[index].value;
                    ScreenRecorder.maxFps = model[index].value;
                }
            }
        }

        SettingRow {
            label: qsTr("Bitrate")
            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.screenRecorder.bitrate)

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

                onMenuItemActivated: index => {
                    Configs.screenRecorder.bitrate = model[index].value;
                    ScreenRecorder.bitrate = model[index].value;
                }
            }
        }

        SettingRow {
            label: qsTr("Video Codec")
            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.screenRecorder.videoCodec)

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

                onMenuItemActivated: index => {
                    Configs.screenRecorder.videoCodec = model[index].value;
                    ScreenRecorder.videoCodec = model[index].value;
                }
            }
        }

        SettingRow {
            label: qsTr("Audio Codec")
            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.screenRecorder.audioCodec)

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

                onMenuItemActivated: index => {
                    Configs.screenRecorder.audioCodec = model[index].value;
                    ScreenRecorder.audioCodec = model[index].value;
                }
            }
        }

        SettingRow {
            label: qsTr("Power Mode")
            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.screenRecorder.lowPower)

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

                onMenuItemActivated: index => {
                    Configs.screenRecorder.lowPower = model[index].value;
                    ScreenRecorder.lowPower = model[index].value;
                }
            }
        }

        SettingRow {
            label: qsTr("Show Cursor")
            StyledSwitch {
                checked: Configs.screenRecorder.showCursor
                onCheckedChanged: {
                    Configs.screenRecorder.showCursor = checked;
                    ScreenRecorder.showCursor = checked;
                }
            }
        }

        SettingRow {
            label: qsTr("Replay Buffer")
            StyledSwitch {
                checked: Configs.screenRecorder.historyMode
                onCheckedChanged: {
                    Configs.screenRecorder.historyMode = checked;
                    ScreenRecorder.historyMode = checked;
                }
            }
        }
    }
}
