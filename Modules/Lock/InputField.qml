import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Components

RowLayout {
	id: root

	required property var pam

	TextField {
		id: passwordBox

		echoMode: TextInput.Password
		focus: true
		enabled: !root.pam.unlockInProgress

		color: root.pam.unlockInProgress ? Themes.colors.on_surface_variant : Themes.colors.on_surface

		font.family: Appearance.fonts.family_Sans
		font.pixelSize: Appearance.fonts.large

		background: StyledRect {
			anchors.fill: parent

			color: passwordBox.activeFocus ? Themes.colors.surface_container_high :
											 Themes.colors.surface_container

			border.color: {
				if (!passwordBox.enabled)
					return Themes.withAlpha(Themes.colors.outline, 0.12);
				else if (passwordBox.activeFocus)
					return Themes.colors.primary;
				else
					return Themes.colors.outline;
			}

			border.width: passwordBox.activeFocus ? 2 : 1
			radius: Appearance.rounding.large

			opacity: passwordBox.enabled ? 1 : 0.38

			Behavior on border.color {
				ColorAnimation {
					duration: Appearance.animations.durations.small
					easing.bezierCurve: Appearance.animations.curves.standard
				}
			}

			Behavior on border.width {
				PropertyAnimation {
					duration: Appearance.animations.durations.small
					easing.bezierCurve: Appearance.animations.curves.standard
				}
			}

			Behavior on color {
				ColorAnimation {
					duration: Appearance.animations.durations.small
					easing.bezierCurve: Appearance.animations.curves.standard
				}
			}

			Behavior on opacity {
				PropertyAnimation {
					duration: Appearance.animations.durations.normal
					easing.bezierCurve: Appearance.animations.curves.standard
				}
			}
		}

		implicitWidth: 320
		implicitHeight: 56

		leftPadding: Appearance.padding.large
		rightPadding: Appearance.padding.large
		topPadding: Appearance.padding.large
		bottomPadding: Appearance.padding.large

		inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText

		placeholderText: root.pam.showFailure ? "Password invalid" : "Enter password"
		placeholderTextColor: root.pam.showFailure ? Themes.colors.error :
													 Themes.colors.on_surface_variant
		font.bold: root.pam.showFailure ? true : false

		selectionColor: Themes.withAlpha(Themes.colors.on_surface, 0.16)
		selectedTextColor: Themes.colors.on_primary

		onAccepted: {
			if (root.pam && text.length > 0)
				root.pam.tryUnlock();
		}

		onTextChanged: {
			if (root.pam) {
				root.pam.currentText = text;
			}
		}

		Layout.alignment: Qt.AlignVCenter

		Connections {
			target: root.pam
			enabled: root.pam !== null

			function onCurrentTextChanged() {
				if (passwordBox.text !== root.pam.currentText) {
					passwordBox.text = root.pam.currentText;
				}
			}
		}

		transform: Scale {
			id: focusScale
			origin.x: passwordBox.width / 2
			origin.y: passwordBox.height / 2
			xScale: passwordBox.activeFocus ? 1.02 : 1.0
			yScale: passwordBox.activeFocus ? 1.02 : 1.0

			Behavior on xScale {
				PropertyAnimation {
					duration: Appearance.animations.durations.normal
					easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
				}
			}

			Behavior on yScale {
				PropertyAnimation {
					duration: Appearance.animations.durations.normal
					easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
				}
			}
		}

		StyledRect {
			anchors.right: parent.right
			anchors.rightMargin: Appearance.padding.large
			anchors.verticalCenter: parent.verticalCenter

			width: 20
			height: 20
			radius: 10
			color: Themes.colors.primary
			visible: root.pam.unlockInProgress
			opacity: visible ? 1 : 0

			SequentialAnimation on color {
				ColAnim {
					to: Themes.colors.primary
				}
				ColAnim {
					to: Themes.colors.secondary
				}
				ColAnim {
					to: Themes.colors.tertiary
				}
				loops: Animation.Infinite
			}

			// RotationAnimator {
			// 	target: root
			// 	running: root.pam.unlockInProgress
			// 	from: 0
			// 	to: 360
			// 	duration: Appearance.animations.durations.extraLarge
			// 	loops: Animation.Infinite
			// }

			Behavior on opacity {
				PropertyAnimation {
					duration: Appearance.animations.durations.small
					easing.bezierCurve: Appearance.animations.curves.standard
				}
			}
		}
	}
}
