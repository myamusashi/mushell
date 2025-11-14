pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Polkit
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Components

Scope {
    id: root

    LazyLoader {
        activeAsync: polkitAgent.isActive

        component: FloatingWindow {
            title: "Authentication Required"
            visible: polkitAgent.isActive
            implicitHeight: contentColumn.implicitHeight + 48
            color: Themes.colors.surface_container_high

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
                    color: Themes.withAlpha(Themes.colors.primary, 0.12)

                    IconImage {
                        id: appIcon

                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        asynchronous: true
                        source: Quickshell.iconPath(
                                    polkitAgent?.flow?.iconName) || ""
                    }
                }

                StyledLabel {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: "Authentication Is Required"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.fonts.extraLarge
                    font.weight: Font.Bold
                    color: Themes.colors.on_surface
                }

                StyledLabel {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: polkitAgent?.flow?.message || "<no message>"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.fonts.large
                    font.weight: Font.Normal
                    color: Themes.colors.on_surface
                }

                StyledLabel {
                    Layout.fillWidth: true
                    text: polkitAgent?.flow?.supplementaryMessage
                          || "Ehh na (no supplementaryMessage)"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.fonts.medium
                    font.weight: Font.Normal
                    color: Themes.colors.on_surface_variant
                    lineHeight: 1.4
                }

                StyledLabel {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: polkitAgent?.flow?.inputPrompt || "<no input prompt>"
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.fonts.medium
                    font.weight: Font.Medium
                    color: Themes.colors.on_surface_variant
                }

                InputField {
                    id: passwordInput
                    polkitAgent: polkitAgent
                }

                StyledLabel {
                    Layout.fillWidth: true
                    text: "Authentication failed. Please try again."
                    color: Themes.colors.error
                    visible: polkitAgent.flow?.failed || 0
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
                        enabled: passwordInput.text.length > 0
                                 || !!polkitAgent?.flow?.isResponseRequired

                        onClicked: {
                            polkitAgent?.flow?.submit(passwordInput.text)
                            passwordInput.text = ""
                            passwordInput.forceActiveFocus()
                        }
                    }

                    StyledButton {
                        buttonTitle: "Cancel"
                        buttonTextColor: Themes.colors.primary
                        buttonColor: "transparent"
                        Layout.preferredHeight: 40
                        visible: polkitAgent.isActive

                        onClicked: {
                            polkitAgent?.flow?.cancelAuthenticationRequest()
                            passwordInput.text = ""
                        }
                    }
                }
            }

            Connections {
                target: polkitAgent?.flow
                function onIsResponseRequiredChanged() {
                    passwordInput.text = ""
                    if (polkitAgent?.flow.isResponseRequired)
                        passwordInput.forceActiveFocus()
                }
            }
        }
    }

    PolkitAgent {
        id: polkitAgent
    }
}
