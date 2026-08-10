import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Menu

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Media Player")

    SettingsCard {
        title: qsTr("Player Preferences")

        SettingRow {
            label: qsTr("Enable lyrics in media player:")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: Configs.mediaPlayer.showLyrics
                onToggled: Configs.mediaPlayer.showLyrics = checked
            }
        }

        SettingRow {
            label: qsTr("Enable dynamic colors from cover art:")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: Configs.mediaPlayer.dynamicColorsCover
                onToggled: Configs.mediaPlayer.dynamicColorsCover = checked
            }
        }

        SettingRow {
            label: qsTr("Slider type:")

            DropdownField {
                id: waveTypeCombo

                Layout.preferredWidth: 250
                model: [
                    {
                        display: "Wavy"
                    },
                    {
                        display: "WaveForm"
                    }
                ]
                currentIndex: -1
                placeholderText: Configs.mediaPlayer.sliderType
                isItemActive: (md, _) => md.display === Configs.mediaPlayer.sliderType
                onActivated: index => Configs.mediaPlayer.sliderType = model[index].display
            }
        }
    }
}
