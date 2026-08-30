pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Components.Base
import qs.Components.Dialog
import qs.Core.Configs
import qs.Services

DialogBox {
    id: root

    property WifiNetwork network: null

    needKeyboardFocus: true
    active: network !== null

    function show(target) {
        network = target;
    }

    header: StyledText {
        text: qsTr("Connect to Wi-Fi")
        color: Colours.m3Colors.m3OnSurface
        elide: Text.ElideMiddle
        font.pixelSize: Appearance.fonts.size.extraLarge
        font.bold: true
    }

    body: ColumnLayout {
        id: passwordBody

        property bool failed: false

        implicitWidth: parent.width
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: root.network ? qsTr("Enter the password for \"%1\"").arg(root.network.name) : qsTr("Enter the Wi-Fi password")
            color: Colours.m3Colors.m3OnSurfaceVariant
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.fonts.size.medium
        }

        StyledTextInput {
            id: passwordField

            Layout.fillWidth: true
            Layout.preferredHeight: 56
            passwordMode: true
            toggleButtonVisible: true
            placeHolderText: passwordBody.failed ? qsTr("Incorrect password") : qsTr("Wi-Fi password")
            onAccepted: passwordBody.submit()
        }

        StyledText {
            Layout.fillWidth: true
            visible: passwordBody.failed
            text: qsTr("Can't connect. Check the password and try again.")
            color: Colours.m3Colors.m3Error
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.fonts.size.small
        }

        Connections {
            target: root

            function onAccepted() {
                passwordBody.submit();
            }

            function onRejected() {
                root.network = null;
            }
        }

        Connections {
            target: root.network
            enabled: root.network !== null

            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets)
                    passwordBody.markFailed();
            }

            function onConnectedChanged() {
                if (root.network?.connected)
                    root.network = null;
            }
        }

        function submit() {
            passwordBody.failed = false;

            if (!root.network || passwordField.text.length === 0)
                return;

            root.network.connectWithPsk(passwordField.text);
        }

        function markFailed() {
            passwordBody.failed = true;
            passwordField.text = "";
            passwordField.forceActiveFocus();
        }
    }
}
