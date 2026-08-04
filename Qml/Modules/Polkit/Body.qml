import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

ColumnLayout {
    property alias passwordInput: passwordInput

    implicitWidth: parent.width
    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 8
        text: PolAgent.agent?.flow?.inputPrompt || qsTr("<no input prompt>") // qmllint disable
        wrapMode: Text.Wrap
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.Medium
        color: Colours.m3Colors.m3OnSurfaceVariant
    }

    InputField {
        id: passwordInput
    }

    StyledText {
        Layout.fillWidth: true
        text: qsTr("Authentication failed. Please try again.")
        color: Colours.m3Colors.m3Error
        visible: PolAgent.agent?.flow?.failed || 0 // qmllint disable
        font.pixelSize: 12
        font.weight: Font.Medium
        leftPadding: 16
    }
}
