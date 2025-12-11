import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Services

StyledTextField {
    id: passwordInput

    Layout.fillWidth: true
    Layout.preferredHeight: 56

    font.family: Appearance.fonts.familySans
    font.pixelSize: Appearance.fonts.large * 1.2
    echoMode: PolAgent.agent?.flow?.responseVisible ? TextInput.Normal : TextInput.Password
    selectByMouse: true
    verticalAlignment: TextInput.AlignVCenter
    leftPadding: 16
    rightPadding: 16

    placeholderText: "Enter password"
}
