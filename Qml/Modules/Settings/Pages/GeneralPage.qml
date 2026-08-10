pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Components.Menu

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

            StyledSwitch {
                checked: Configs.generals.followFocusMonitor
                onCheckedChanged: Configs.generals.followFocusMonitor = checked
            }
        }

        SettingRow {
            label: qsTr("Enable Transparent Mode:")

            StyledSwitch {
                checked: Configs.generals.transparent
                onCheckedChanged: Configs.generals.transparent = checked
            }
        }

        SettingRow {
            label: qsTr("Transparency Alpha:")

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
            label: qsTr("How far the charging indicator spreads on the screen edge:")

            StyledSlide {
                from: 1
                to: 64
                value: Configs.generals.chargingGlowSpread
                onMoved: Configs.generals.chargingGlowSpread = value
                Layout.preferredWidth: 200
            }
        }

        SettingRow {
            label: qsTr("Enable Outer Border:")

            StyledSwitch {
                checked: Configs.generals.enableOuterBorder
                onCheckedChanged: Configs.generals.enableOuterBorder = checked
            }
        }

        SettingRow {
            label: qsTr("Show Holidays in Calendar:")

            StyledSwitch {
                checked: Configs.generals.showHolidays
                onCheckedChanged: Configs.generals.showHolidays = checked
            }
        }
    }

    SettingsCard {
        title: qsTr("Default Applications")

        AppSettingRow {
            label: qsTr("Terminal:")
            categories: ["TerminalEmulator"]
            configValue: Configs.generals.apps.terminal
            onConfigChanged: value => Configs.generals.apps.terminal = value
        }
        AppSettingRow {
            label: qsTr("File Explorer:")
            categories: ["FileManager"]
            configValue: Configs.generals.apps.fileExplorer
            onConfigChanged: value => Configs.generals.apps.fileExplorer = value
        }
        AppSettingRow {
            label: qsTr("Image Viewer:")
            categories: ["Viewer"]
            configValue: Configs.generals.apps.imageViewer
            onConfigChanged: value => Configs.generals.apps.imageViewer = value
        }
        AppSettingRow {
            label: qsTr("Video Viewer:")
            categories: ["Video"]
            configValue: Configs.generals.apps.videoViewer
            onConfigChanged: value => Configs.generals.apps.videoViewer = value
        }
        AppSettingRow {
            label: qsTr("Audio Settings:")
            categories: ["AudioVideo", "Settings"]
            configValue: Configs.generals.apps.audio
            onConfigChanged: value => Configs.generals.apps.audio = value
        }
    }

    component AppSettingRow: SettingRow {
        id: appSettingRow

        property var categories: []
        property string configValue
        signal configChanged(string value)

        onConfigValueChanged: appCombo.currentIndex = appModel.values.findIndex(item => item.display === configValue)

        DropdownField {
            id: appCombo

            Layout.preferredWidth: 250
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
            currentIndex: appModel.values.findIndex(item => item.display === appSettingRow.configValue)
            placeholderText: appSettingRow.configValue
            isItemActive: (md, _) => md.display === appSettingRow.configValue
            onActivated: index => appSettingRow.configChanged(appModel.values[index].display)
        }
    }
}
