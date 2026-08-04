import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("System Language")

    SettingsCard {
        title: qsTr("Locale Preference")

        SettingRow {
            label: qsTr("Current Language:")

            StyledTextInput {
                text: Configs.language.language
                onTextChanged: Configs.language.language = text
                Layout.preferredWidth: 200
                placeHolderText: "e.g., id-ID or en-US"
                toggleButtonVisible: false
            }
        }
    }
}
