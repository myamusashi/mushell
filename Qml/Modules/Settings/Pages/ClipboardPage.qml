import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Clipboard configurations")

    SettingsCard {
        title: qsTr("General Settings")

        GridLayout {
            columns: 2

            SettingRow {
                label: qsTr("Enable Clipboard:")
                description: qsTr("Turn on clipboard manager.")

                StyledSwitch {
                    checked: Configs.clipboard.enabled
                    onCheckedChanged: Configs.clipboard.enabled = checked
                }
            }

            SettingRow {
                label: qsTr("Enable Previews:")
                description: qsTr("Show thumbnail previews in the clipboard.")

                StyledSwitch {
                    checked: Configs.clipboard.enablePreview
                    onCheckedChanged: Configs.clipboard.enablePreview = checked
                }
            }

            SettingRow {
                label: qsTr("Enable Vim Keybinds:")
                description: qsTr("Use Vim-style navigation inside the clipboard manager.")

                StyledSwitch {
                    checked: Configs.clipboard.enableVimKeybinds
                    onCheckedChanged: Configs.clipboard.enableVimKeybinds = checked
                }
            }

            SettingRow {
                label: qsTr("Keep Clipboard Open After Copy:")
                description: qsTr("Keep the clipboard window open after copying an entry.")

                StyledSwitch {
                    checked: Configs.clipboard.keepOpenAfterCopy
                    onCheckedChanged: Configs.clipboard.keepOpenAfterCopy = checked
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Preview Dimensions")
        visible: Configs.clipboard.enablePreview

        SettingRow {
            label: qsTr("Preview Width:")
            description: qsTr("Width of the clipboard preview in pixels.")

            StyledSlide {
                from: 100
                to: 1000
                stepSize: 10
                value: Configs.clipboard.preview.sourceWidth
                onMoved: Configs.clipboard.preview.sourceWidth = value
                Layout.preferredWidth: 200
            }
        }

        SettingRow {
            label: qsTr("Preview Height:")
            description: qsTr("Height of the clipboard preview in pixels.")

            StyledSlide {
                from: 100
                to: 1000
                stepSize: 10
                value: Configs.clipboard.preview.sourceHeight
                onMoved: Configs.clipboard.preview.sourceHeight = value
                Layout.preferredWidth: 200
            }
        }
    }
}
