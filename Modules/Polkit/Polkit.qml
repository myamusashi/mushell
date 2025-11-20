pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services as Pol
import qs.Components

LazyLoader {
    activeAsync: Pol.PolAgent.agent.isActive

    component: FloatingWindow {
        title: "Authentication Required"
        visible: Pol.PolAgent.agent.isActive
        implicitHeight: contentColumn.implicitHeight + 48
        color: Themes.m3Colors.surfaceContainerHigh

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 24
            spacing: Appearance.spacing.large

            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                Layout.topMargin: 8
                radius: Appearance.rounding.full
                color: Themes.withAlpha(Themes.m3Colors.primary, 0.12)

                IconImage {
                    id: appIcon

                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    asynchronous: true
                    source: Quickshell.iconPath(Pol.PolAgent.agent?.flow?.iconName) || ""
                }
            }

            StyledLabel {
                Layout.fillWidth: true
                Layout.topMargin: 8
                text: "Authentication Is Required"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.fonts.extraLarge
                font.weight: Font.Bold
                color: Themes.m3Colors.onSurface
            }

            StyledLabel {
                Layout.fillWidth: true
                Layout.topMargin: 8
                text: Pol.PolAgent.agent?.flow?.message || "<no message>"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.fonts.large
                font.weight: Font.Normal
                color: Themes.m3Colors.onSurface
            }

            StyledLabel {
                Layout.fillWidth: true
                text: Pol.PolAgent.agent?.flow?.supplementaryMessage || "Ehh na (no supplementaryMessage)"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.fonts.medium
                font.weight: Font.Normal
                color: Themes.m3Colors.onSurfaceVariant
                lineHeight: 1.4
            }

            StyledLabel {
                Layout.fillWidth: true
                Layout.topMargin: 8
                text: Pol.PolAgent.agent?.flow?.inputPrompt || "<no input prompt>"
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.fonts.medium
                font.weight: Font.Medium
                color: Themes.m3Colors.onSurfaceVariant
            }

            InputField {
                id: passwordInput
            }

            StyledLabel {
                Layout.fillWidth: true
                text: "Authentication failed. Please try again."
                color: Themes.m3Colors.error
                visible: Pol.PolAgent.agent?.flow?.failed || 0
                font.pixelSize: 12
                font.weight: Font.Medium
                leftPadding: 16
            }

            Item {
                Layout.fillHeight: true
                Layout.preferredHeight: 8
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8
                layoutDirection: Qt.RightToLeft

                StyledButton {
                    id: okButton

                    buttonTitle: "Authenticate"
                    Layout.preferredHeight: 40
                    enabled: passwordInput.text.length > 0 || !!Pol.PolAgent.agent?.flow?.isResponseRequired

                    onClicked: {
                        Pol.PolAgent.agent?.flow?.submit(passwordInput.text);
                        passwordInput.text = "";
                        passwordInput.forceActiveFocus();
                    }
                }

                StyledButton {
                    buttonTitle: "Cancel"
                    buttonTextColor: Themes.m3Colors.primary
                    buttonColor: "transparent"
                    Layout.preferredHeight: 40
                    visible: Pol.PolAgent.agent?.isActive

                    onClicked: {
                        Pol.PolAgent.agent?.flow?.cancelAuthenticationRequest();
                        passwordInput.text = "";
                    }
                }
            }
        }

        Connections {
            target: Pol.PolAgent.agent?.flow
            function onIsResponseRequiredChanged() {
                passwordInput.text = "";
                if (Pol.PolAgent.agent?.flow.isResponseRequired)
                    passwordInput.forceActiveFocus();
            }
        }
    }
}
