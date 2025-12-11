import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Services

ColumnLayout {
    property alias passwordInput: passwordInput

    implicitWidth: parent.width
    StyledLabel {
        Layout.fillWidth: true
        Layout.topMargin: 8
        text: PolAgent.agent?.flow?.inputPrompt || "<no input prompt>"
        wrapMode: Text.Wrap
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.Medium
        color: Colours.m3Colors.m3OnSurfaceVariant
    }

    InputField {
        id: passwordInput
    }

    StyledLabel {
        Layout.fillWidth: true
        text: "Authentication failed. Please try again."
        color: Colours.m3Colors.m3Error
        visible: PolAgent.agent?.flow?.failed || 0
        font.pixelSize: 12
        font.weight: Font.Medium
        leftPadding: 16
    }
}
