pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components.Button

import qs.Core.Configs
import qs.Services
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("General Settings")

    function cleanExec(exec) {
        return exec.replace(/%[uUfFdDnNickvm]/g, "").replace(/--\S+/g, "").replace(/--/g, "").trim();
    }

    SettingsCard {
        title: qsTr("Window & Focus")

        SettingRow {
            label: qsTr("Follow Focus Monitor:")
            description: qsTr("Automatically switch the active drawers to the monitor where cursor in.")

            StyledSwitch {
                checked: Configs.generals.followFocusMonitor
                onCheckedChanged: Configs.generals.followFocusMonitor = checked
            }
        }

        SettingRow {
            label: qsTr("Show Holidays in Calendar:")
            description: qsTr("Display public holidays inside the calendar widget (NOTE: not every country).")

            StyledSwitch {
                checked: Configs.generals.showHolidays
                onCheckedChanged: Configs.generals.showHolidays = checked
            }
        }

        SettingRow {
            label: qsTr("Enable Outer Border:")
            description: qsTr("Draw an outer border around shell.")

            StyledSwitch {
                checked: Configs.generals.enableOuterBorder
                onCheckedChanged: Configs.generals.enableOuterBorder = checked
            }
        }

        GridLayout {
            columns: 2

            // transparency sections
            SettingRow {
                label: qsTr("Enable Transparent Mode:")
                description: qsTr("Enable translucent shell.")

                StyledSwitch {
                    checked: Configs.generals.transparent
                    onCheckedChanged: Configs.generals.transparent = checked
                }
            }

            SettingRow {
                label: qsTr("Transparency Alpha:")
                description: qsTr("Lower is more transparent.")

                StyledSlide {
                    from: 0.1
                    to: 1.0
                    stepSize: 0.1
                    popupDecimals: 1
                    value: Configs.generals.alpha
                    onMoved: Configs.generals.alpha = value
                    Layout.preferredWidth: 200
                    filledRectColor: {
                        if (!enabled)
                            Colours.m3Colors.m3OnSurface;
                        else
                            Colours.m3Colors.m3Primary;
                    }
                    emptyRectColor: {
                        if (!enabled)
                            Colours.m3Colors.m3OnSurface;
                        else
                            Colours.m3Colors.m3SurfaceContainerHighest;
                    }
                    handleColor: {
                        if (!enabled)
                            Colours.m3Colors.m3InverseOnSurface;
                        else
                            Colours.m3Colors.m3Primary;
                    }
                    filledRectOpacity: {
                        if (!enabled)
                            return 0.38;
                        else
                            return 1.0;
                    }
                    emptyRectOpacity: {
                        if (!enabled)
                            return 0.12;
                        else
                            return 1.0;
                    }
                    handleOpacity: {
                        if (!enabled)
                            return 0.38;
                        else
                            return 1.0;
                    }
                    enabled: Configs.generals.transparent
                }
            }
            // transparency sections end

            SettingRow {
                label: qsTr("How much radius blur for album cover:")

                StyledSlide {
                    from: 1
                    to: 64
                    value: Configs.generals.coverBlurRadius
                    onMoved: Configs.generals.coverBlurRadius = value
                    Layout.preferredWidth: 200
                }
            }

            SettingRow {
                label: qsTr("Charging indicator spreads on the screen edge:")
                description: qsTr("Thickness of the glowing edge indicator when charging detected.")

                StyledSlide {
                    from: 1
                    to: 64
                    value: Configs.generals.chargingGlowSpread
                    onMoved: Configs.generals.chargingGlowSpread = value
                    Layout.preferredWidth: 200
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Default Applications")

        GridLayout {
            columns: 2

            AppSettingRow {
                label: qsTr("Terminal:")
                description: qsTr("Default terminal emulator for opening shell commands.")
                categories: ["TerminalEmulator"]
                configValue: Configs.generals.apps.terminal
                onConfigChanged: value => Configs.generals.apps.terminal = value
            }
            AppSettingRow {
                label: qsTr("File Explorer:")
                description: qsTr("Default file manager for opening folders.")
                categories: ["FileManager"]
                configValue: Configs.generals.apps.fileExplorer
                onConfigChanged: value => Configs.generals.apps.fileExplorer = value
            }
            AppSettingRow {
                label: qsTr("Image Viewer:")
                description: qsTr("Default app for viewing images.")
                categories: ["Viewer"]
                configValue: Configs.generals.apps.imageViewer
                onConfigChanged: value => Configs.generals.apps.imageViewer = value
            }
            AppSettingRow {
                label: qsTr("Video Viewer:")
                description: qsTr("Default app for playing videos.")
                categories: ["Video"]
                configValue: Configs.generals.apps.videoViewer
                onConfigChanged: value => Configs.generals.apps.videoViewer = value
            }
            AppSettingRow {
                label: qsTr("Audio Settings:")
                description: qsTr("Default app for audio and sound configuration.")
                categories: ["AudioVideo", "Settings"]
                configValue: Configs.generals.apps.audio
                onConfigChanged: value => Configs.generals.apps.audio = value
            }
        }
    }

    component AppSettingRow: SettingRow {
        id: appSettingRow

        property var categories: []
        property string configValue
        signal configChanged(string value)

        onConfigValueChanged: appCombo.currentIndex = appModel.values.findIndex(item => item.display === configValue)

        SplitButton {
            id: appCombo

            model: ScriptModel {
                id: appModel

                values: {
                    const apps = [...DesktopEntries.applications.values];
                    const filtered = apps.filter(e => appSettingRow.categories.every(c => e.categories.includes(c)));
                    const mapped = filtered.map(e => ({
                                e,
                                display: e.execString.replace(/%[uUfFdDnNickvm]/g, "").replace(/--\S+/g, "").replace(/--/g, "").trim()
                            }));
                    return [...new Map(mapped.map(e => [e.display, e])).values()];
                }
            }
            textRole: "display"
            icon.name: appSettingRow.categories.reduce((acc, item) => {
                switch (item) {
                case "TerminalEmulator":
                    return "terminal";
                case "FileManager":
                    return "folder_open";
                case "Viewer":
                    return "imagesmode";
                case "Video":
                    return "video_file";
                case "AudioVideo":
                    return "audio_file";
                default:
                    return acc;
                }
            }, "apps")
            currentIndex: appModel.values.findIndex(item => item.display === appSettingRow.configValue)
            text: appModel.values[currentIndex]?.display ?? appSettingRow.configValue

            onMenuItemActivated: index => appSettingRow.configChanged(appModel.values[index].display)
        }
    }
}
