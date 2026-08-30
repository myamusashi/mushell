import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

ColumnLayout {
    id: root

    // AuthFlow state; null-safe because the flow only exists during an active request.
    readonly property string supplementaryMessage: PolAgent.agent?.flow?.supplementaryMessage ?? "" // qmllint disable
    readonly property bool supplementaryIsError: PolAgent.agent?.flow?.supplementaryIsError ?? false // qmllint disable
    readonly property bool authenticationFailed: PolAgent.agent?.flow?.failed ?? false // qmllint disable
    readonly property bool responseVisible: PolAgent.agent?.flow?.responseVisible ?? false // qmllint disable

    property alias passwordInput: passwordInput
    implicitWidth: parent.width

    spacing: Appearance.spacing.small

    function submit() {
        const response = passwordInput.text;

        passwordInput.text = "";
        if (response.length > 0)
            PolAgent.submit(response);
    }

    function cancel() {
        passwordInput.text = "";
        PolAgent.cancel();
    }

    StyledText {
        Layout.fillWidth: true
        text: PolAgent.agent?.flow?.inputPrompt ?? "" // qmllint disable
        visible: text !== ""
        wrapMode: Text.Wrap
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.Medium
        color: Colours.m3Colors.m3OnSurfaceVariant
    }

    StyledTextInput {
        id: passwordInput

        Layout.fillWidth: true
        Layout.preferredHeight: 44
        placeHolderText: qsTr("Enter password")
        passwordMode: !root.responseVisible
        onAccepted: root.submit()
        onKeyPressed: event => {
            if (event.key === Qt.Key_Escape && !event.accepted)
                root.cancel();
        }
    }

    StyledText {
        Layout.fillWidth: true
        text: root.supplementaryMessage
        visible: text !== ""
        wrapMode: Text.Wrap
        font.pixelSize: Appearance.fonts.size.small
        font.weight: Font.Medium
        color: root.supplementaryIsError ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
    }

    StyledText {
        Layout.fillWidth: true
        text: qsTr("Authentication failed. Please try again.")
        visible: root.authenticationFailed && root.supplementaryMessage === ""
        wrapMode: Text.Wrap
        font.pixelSize: Appearance.fonts.size.small
        font.weight: Font.Medium
        color: Colours.m3Colors.m3Error
    }
}
