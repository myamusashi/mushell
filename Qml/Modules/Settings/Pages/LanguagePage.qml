import QtQuick

import qs.Components.Button
import qs.Core.Configs

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("System Language")

    SettingsCard {
        title: qsTr("Locale Preference")

        SettingRow {
            label: qsTr("Current Language:")
            description: qsTr("Locale code used for translations.")

            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.display === Configs.language.language)

                model: [
                    {
                        display: "id_ID"
                    },
                    {
                        display: "en_US"
                    }
                ]
                textRole: "display"
                icon.name: "language"
                currentIndex: selectedIndex
                text: model[selectedIndex]?.dispaly ?? Configs.language.language
                onMenuItemActivated: index => Configs.language.language = model[index].display
            }
        }
    }
}
