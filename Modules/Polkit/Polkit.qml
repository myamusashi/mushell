pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Polkit
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: root

	LazyLoader {
		active: polkitAgent.isActive

		component: FloatingWindow {
			title: "Authentication Required"
			visible: polkitAgent.isActive
			implicitHeight: contentColumn.implicitHeight + 48
			color: Colors.colors.surface_container_high

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
					color: Colors.withAlpha(Colors.colors.primary, 0.12)

					IconImage {
						id: appIcon

						anchors.centerIn: parent
						width: 40
						height: 40
						asynchronous: true
						source: Quickshell.iconPath(polkitAgent?.flow?.iconName) || ""
					}
				}

				StyledLabel {
					Layout.fillWidth: true
					Layout.topMargin: 8
					text: "Authentication Is Required"
					horizontalAlignment: Text.AlignHCenter
					font.pixelSize: Appearance.fonts.extraLarge
					font.weight: Font.Bold
					color: Colors.colors.on_surface
				}

				StyledLabel {
					Layout.fillWidth: true
					Layout.topMargin: 8
					text: polkitAgent?.flow?.message || "<no message>"
					wrapMode: Text.Wrap
					horizontalAlignment: Text.AlignHCenter
					font.pixelSize: Appearance.fonts.large
					font.weight: Font.Normal
					color: Colors.colors.on_surface
				}

				StyledLabel {
					Layout.fillWidth: true
					text: polkitAgent?.flow?.supplementaryMessage || "Ehh na (no supplementaryMessage)"
					wrapMode: Text.Wrap
					horizontalAlignment: Text.AlignHCenter
					font.pixelSize: Appearance.fonts.medium
					font.weight: Font.Normal
					color: Colors.colors.on_surface_variant
					lineHeight: 1.4
				}

				StyledLabel {
					Layout.fillWidth: true
					Layout.topMargin: 8
					text: polkitAgent?.flow?.inputPrompt || "<no input prompt>"
					wrapMode: Text.Wrap
					font.pixelSize: Appearance.fonts.medium
					font.weight: Font.Medium
					color: Colors.colors.on_surface_variant
				}

				TextField {
					id: passwordInput

					Layout.fillWidth: true
					Layout.preferredHeight: 56

					font.family: Appearance.fonts.family_Sans
					font.pixelSize: Appearance.fonts.large * 1.2
					echoMode: polkitAgent?.flow?.responseVisible ? TextInput.Normal : TextInput.Password
					selectByMouse: true
					verticalAlignment: TextInput.AlignVCenter
					leftPadding: 16
					rightPadding: 16
					color: Colors.colors.on_surface

					placeholderText: "Enter password"
					placeholderTextColor: Colors.colors.on_surface_variant

					background: Rectangle {
						anchors.fill: parent
						color: "transparent"
						radius: Appearance.rounding.small

						border.color: {
							if (!passwordInput.enabled)
								return Colors.withAlpha(Colors.colors.outline, 0.38);
							else if (passwordInput.activeFocus)
								return Colors.colors.primary;
							else
								return Colors.colors.outline;
						}
						border.width: passwordInput.activeFocus ? 2 : 1

						Rectangle {
							anchors.fill: parent
							radius: parent.radius
							color: {
								if (!passwordInput.enabled)
									return "transparent";
								else if (passwordInput.activeFocus)
									return Colors.withAlpha(Colors.colors.primary, 0.08);
								else
									return "transparent";
							}

							Behavior on color {
								ColAnim {
									duration: Appearance.animations.durations.small
									easing.type: Easing.OutCubic
								}
							}
						}

						Behavior on border.color {
							ColAnim {
								duration: Appearance.animations.durations.small
								easing.type: Easing.OutCubic
							}
						}

						Behavior on border.width {
							PropertyAnimation {
								duration: Appearance.animations.durations.small
								easing.type: Easing.OutCubic
							}
						}
					}

					selectionColor: Colors.withAlpha(Colors.colors.primary, 0.24)
					selectedTextColor: Colors.colors.on_surface

					onAccepted: okButton.clicked()
				}

				StyledLabel {
					Layout.fillWidth: true
					text: "Authentication failed. Please try again."
					color: Colors.colors.error
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
						buttonTextColor: Colors.colors.on_primary
						buttonColor: Colors.colors.primary
						buttonHoverColor: Colors.colors.primary
						buttonPressedColor: Colors.colors.primary
						Layout.preferredHeight: 40
						enabled: passwordInput.text.length > 0 || !!polkitAgent?.flow?.isResponseRequired

						background: Rectangle {
							implicitWidth: okButton.implicitWidth
							implicitHeight: 40
							radius: Appearance.rounding.large
							color: okButton.enabled ? Colors.colors.primary : Colors.withAlpha(Colors.colors.on_surface, 0.12)

							Rectangle {
								anchors.fill: parent
								radius: parent.radius
								color: {
									if (!okButton.enabled)
										return "transparent";
									else if (okButton.pressed)
										return Colors.withAlpha(Colors.colors.on_primary, 0.12);
									else if (okButton.hovered)
										return Colors.withAlpha(Colors.colors.on_primary, 0.08);
									else
										return "transparent";
								}

								Behavior on color {
									ColAnim {
										duration: Appearance.animations.durations.small
										easing.type: Easing.OutCubic
									}
								}
							}

							Behavior on color {
								ColAnim {
									duration: Appearance.animations.durations.small
									easing.type: Easing.OutCubic
								}
							}
						}

						onClicked: {
							polkitAgent?.flow?.submit(passwordInput.text);
							passwordInput.text = "";
							passwordInput.forceActiveFocus();
						}
					}

					StyledButton {
						buttonTitle: "Cancel"
						buttonTextColor: Colors.colors.primary
						buttonColor: "transparent"
						buttonHoverColor: Colors.withAlpha(Colors.colors.primary, 0.08)
						buttonPressedColor: Colors.withAlpha(Colors.colors.primary, 0.12)
						Layout.preferredHeight: 40
						visible: polkitAgent.isActive

						onClicked: {
							polkitAgent?.flow?.cancelAuthenticationRequest();
							passwordInput.text = "";
						}
					}
				}
			}

			Connections {
				target: polkitAgent?.flow
				function onIsResponseRequiredChanged() {
					passwordInput.text = "";
					if (polkitAgent?.flow.isResponseRequired)
						passwordInput.forceActiveFocus();
				}
			}
		}
	}

	PolkitAgent {
		id: polkitAgent
	}
}
