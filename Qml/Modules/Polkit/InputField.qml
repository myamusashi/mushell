import QtQuick
import QtQuick.Layouts

import qs.Components.Base

StyledTextInput {
    id: passwordInput

    Layout.fillWidth: true
    Layout.preferredHeight: 44
    placeHolderText: qsTr("Enter password")
}
