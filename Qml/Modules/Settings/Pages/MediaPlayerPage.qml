import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Button
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Media Player")

    SettingsCard {
        title: qsTr("Player Preferences")

        SettingRow {
            label: qsTr("Enable lyrics in media player:")
            description: qsTr("Fetch and display synchronized lyrics when available.")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: Configs.mediaPlayer.showLyrics
                onToggled: Configs.mediaPlayer.showLyrics = checked
            }
        }

        SettingRow {
            label: qsTr("Enable dynamic colors from cover art:")
            description: qsTr("Tint the player with colors extracted from the album cover.")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: Configs.mediaPlayer.dynamicColorsCover
                onToggled: Configs.mediaPlayer.dynamicColorsCover = checked
            }
        }

        SettingRow {
            label: qsTr("Slider type:")
            description: qsTr("Visual style for the playback progress slider.")

            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.display === Configs.mediaPlayer.sliderType)

                model: [
                    {
                        display: "Wavy"
                    },
                    {
                        display: "WaveForm"
                    }
                ]
                textRole: "display"
                currentIndex: selectedIndex
                text: model[selectedIndex]?.display ?? Configs.mediaPlayer.sliderType
                icon.name: "sliders"

                onMenuItemActivated: index => Configs.mediaPlayer.sliderType = model[index].display
            }
        }
    }
}
