pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: root

	property var screen
	property bool isMenuOpen: false

	Variants {
		model: Quickshell.screens

		delegate: PanelWindow {

			required property ShellScreen modelData

			anchors {
				top: true
				left: true
			}

			margins.left: 10
			margins.top: 20

			width: 120
			height: 250
			screen: modelData
			color: Colors.colors.background
			visible: root.isMenuOpen

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: Appearance.spacing.normal
				spacing: Appearance.spacing.normal

				Repeater {
					model: [
						{
							icon: "dashboard",
							name: "Dashboard",
							action: () => {
								Quickshell.execDetached({
									command: ["sh", "-c", "qs -c lock ipc call dashboard toggle"]
								});
							}
						},
						{
							icon: "apps",
							name: "App launcher",
							action: () => {
								Quickshell.execDetached({
									command: ["sh", "-c", "qs -c lock ipc call launcher toggle"]
								});
							}
						},
						{
							icon: "screenshow_frame",
							name: "Screen capture",
							action: () => {
								Quickshell.execDetached({
									command: ["sh", "-c", "qs -c lock ipc call screencapture toggle"]
								});
							}
						},
						{
							icon: "power_settings_circle",
							name: "Session",
							action: () => {
								Quickshell.execDetached({
									command: ["sh", "-c", "qs -c lock ipc call session toggle"]
								});
							}
						},
					]

					delegate: MouseArea {
						id: delegateItem

						Layout.fillWidth: true
						Layout.fillHeight: true

						Layout.preferredHeight: 40

						required property var modelData

						anchors.margins: Appearance.spacing.small

						MatIcon {
							icon: delegateItem.modelData.icon
							Layout.alignment: Qt.AlignVCenter
						}

						StyledText {
							text: delegateItem.modelData.name
							color: Colors.colors.on_background
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignVCenter
						}

						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: delegateItem.modelData.action()
					}
				}
			}
		}
	}
}
