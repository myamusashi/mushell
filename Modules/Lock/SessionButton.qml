pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Data
import qs.Helpers
import qs.Components

RowLayout {
	id: root

	property bool isOpen

	ColumnLayout {
		Layout.alignment: Qt.AlignCenter

		StyledRect {
			id: mainButton

			Layout.preferredWidth: 56 + propertySplitButton.width
			Layout.preferredHeight: 56

			color: {
				if (mouseAreaMain.containsPress)
				Themes.withAlpha(Themes.colors.primary, 0.08);
				else if (mouseAreaMain.containsMouse)
				Themes.withAlpha(Themes.colors.primary, 0.1);
				else
				Themes.colors.primary;
			}

			radius: Appearance.rounding.full

			RowLayout {
				id: propertySplitButton

				anchors.centerIn: parent
				spacing: Appearance.spacing.small

				MatIcon {
					icon: "power_settings_circle"
					color: Themes.colors.on_primary
					font.pixelSize: Appearance.fonts.extraLarge
				}

				StyledText {
					text: "Shutdown"
					color: Themes.colors.on_primary
					font.pixelSize: Appearance.fonts.large
				}
			}

			MArea {
				id: mouseAreaMain

				anchors.fill: parent

				hoverEnabled: true

				cursorShape: Qt.PointingHandCursor
				onClicked: {
					Quickshell.execDetached({
												command: ["sh", "-c", "systemctl poweroff"]
											});
				}
			}
		}

		Repeater {
			model: [
				{
					icon: "restart_alt",
					name: "Reboot",
					action: () => {
						Quickshell.execDetached({
													command: ["sh", "-c", "systemctl reboot"]
												});
					}
				},
				{
					icon: "sleep",
					name: "Sleep",
					action: () => {
						Quickshell.execDetached({
													command: ["sh", "-c", "systemctl suspend"]
												});
					}
				},
				{
					icon: "door_open",
					name: "Logout",
					action: () => {
						Quickshell.execDetached({
													command: ["sh", "-c", "hyprctl dispatch exit"]
												});
					}
				},
			]

			delegate: StyledRect {
				id: buttonDelegate

				required property var modelData

				Layout.preferredWidth: mainButton.width
				Layout.preferredHeight: root.isOpen ? 56 : 0

				color: mouseArea.pressed ? Themes.withAlpha(Themes.colors.primary, 0.08) :
										   mouseArea.containsMouse ? Themes.withAlpha(Themes.colors.primary, 0.1) :
																	 Themes.colors.primary

				radius: Appearance.rounding.full

				visible: root.isOpen || Layout.bottomMargin > -height

				Layout.topMargin: root.isOpen ? Appearance.spacing.normal : 0

				Behavior on Layout.preferredHeight {
					NumbAnim {
						duration: Appearance.animations.durations.small
						easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
					}
				}

				Behavior on opacity {
					NumbAnim {
						duration: Appearance.animations.durations.small
					}
				}

				Behavior on Layout.topMargin {
					NumbAnim {
						duration: Appearance.animations.durations.small
						easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
					}
				}

				RowLayout {
					id: propertyButton

					anchors.centerIn: parent
					spacing: Appearance.spacing.small

					MatIcon {
						icon: buttonDelegate.modelData.icon
						color: Themes.colors.on_primary
						font.pixelSize: Appearance.fonts.extraLarge
					}

					StyledText {
						text: buttonDelegate.modelData.name
						color: Themes.colors.on_primary
						font.pixelSize: Appearance.fonts.large
					}
				}

				MArea {
					id: mouseArea

					anchors.fill: parent

					hoverEnabled: true

					cursorShape: Qt.PointingHandCursor
					onClicked: buttonDelegate.modelData.action()
				}
			}
		}
	}

	StyledRect {
		id: toggleButton

		Layout.alignment: Qt.AlignBottom

		Layout.preferredWidth: 56
		Layout.preferredHeight: 56

		color: {
			if (mouseAreaToggle.containsPress)
			Themes.withAlpha(Themes.colors.primary, 0.08);
			else if (mouseAreaToggle.containsMouse)
			Themes.withAlpha(Themes.colors.primary, 0.1);
			else
			Themes.colors.primary;
		}

		radius: Appearance.rounding.full

		MatIcon {
			id: arrowIcon

			anchors.centerIn: parent
			icon: root.isOpen ? "keyboard_arrow_down" : "keyboard_arrow_up"
			color: Themes.colors.on_primary
			font.pixelSize: Appearance.fonts.extraLarge

			RotationAnimator on rotation {
				id: rotateArrowIcon

				from: 0
				to: 180
				duration: Appearance.animations.durations.normal
				easing.type: Easing.BezierSpline
				easing.bezierCurve: Appearance.animations.curves.standard
				running: false
			}
		}

		MArea {
			id: mouseAreaToggle

			anchors.fill: parent

			hoverEnabled: true

			cursorShape: Qt.PointingHandCursor
			onClicked: {
				root.isOpen = !root.isOpen;
				rotateArrowIcon.running = !rotateArrowIcon.running;
			}
		}
	}
}
