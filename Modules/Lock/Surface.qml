pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Data
import qs.Components

WlSessionLockSurface {
	id: root

	required property WlSessionLock lock
	required property Pam pam

	Connections {
		target: root.lock

		function onUnlock(): void {
			unlockSequence.start();
		}
	}

	FileView {
		id: wallFile

		path: Quickshell.env("HOME") + "/.cache/wall/path.txt"
		watchChanges: true
		onFileChanged: reload()
	}

	StyledRect {
		id: surface

		anchors.fill: parent

		color: Colors.colors.surface_container_lowest

		Image {
			id: wallpaper

			anchors.fill: parent
			antialiasing: true
			asynchronous: true
			retainWhileLoading: true
			smooth: true
			opacity: 1
			fillMode: Image.PreserveAspectCrop
			source: wallFile.text().trim()
			// layer.enabled: true
			// layer.effect: MultiEffect {
			// 	id: wallBlur
			//
			// 	autoPaddingEnabled: false
			// 	blurEnabled: true
			//
			// 	NumbAnim on blur {
			// 		easing.type: Easing.Linear
			// 		from: 0
			// 		to: 0.69
			// 	}
			//
			// 	NumbAnim {
			// 		easing.type: Easing.Linear
			// 		duration: Appearance.animations.durations.large
			// 		property: "blur"
			// 		running: root.lock.locked
			// 		target: wallBlur
			// 		to: 0
			// 	}
			// }
		}

		// ScreencopyView {
		// 	id: wallpaper
		//
		// 	anchors.fill: parent
		//
		// 	captureSource: root.screen
		// 	opacity: 1
		// 	visible: true
		// 	layer.enabled: true
		// 	layer.effect: MultiEffect {
		// 		id: wallBlur
		//
		// 		autoPaddingEnabled: false
		// 		blurEnabled: true
		//
		// 		NumbAnim on blur {
		// 			from: 0
		// 			to: 0.69
		// 		}
		//
		// 		NumbAnim {
		// 			duration: Appearance.animations.durations.large
		// 			property: "blur"
		// 			running: root.lock.locked
		// 			target: wallBlur
		// 			to: 0
		// 		}
		// 	}
		// }

		ColumnLayout {
			id: clockContainer

			anchors {
				centerIn: parent
				verticalCenterOffset: -80
			}
			spacing: Appearance.spacing.normal
			opacity: 0
			scale: 0.8

			Clock {}
		}

		ColumnLayout {
			id: inputContainer

			spacing: Appearance.spacing.larger
			opacity: 0
			scale: 0.95

			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				bottomMargin: Appearance.spacing.large * 4
			}

			InputField {
				pam: root.pam
			}
		}

		ColumnLayout {
			id: sessionContainer

			spacing: Appearance.spacing.normal
			opacity: 0
			scale: 0.8

			anchors {
				right: parent.right
				bottom: parent.bottom
				margins: Appearance.spacing.large
			}

			SessionButton {}
		}
	}

	SequentialAnimation {
		id: unlockSequence

		ParallelAnimation {
			PropertyAnimation {
				target: clockContainer
				properties: "opacity,scale"

				from: 1
				to: 0
				duration: Appearance.animations.durations.expressiveFastSpatial
				easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
			}

			PropertyAnimation {
				target: inputContainer
				properties: "opacity,scale"

				from: 1
				to: 0
				duration: Appearance.animations.durations.normal
				easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
			}

			PropertyAnimation {
				target: sessionContainer
				properties: "opacity,scale"

				from: 1
				to: 0
				duration: Appearance.animations.durations.normal
				easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
			}
		}

		PropertyAction {
			target: root.lock
			property: "locked"
			value: false
		}
	}

	SequentialAnimation {
		id: entrySequence

		running: true

		ParallelAnimation {
			SequentialAnimation {
				PauseAnimation {
					duration: Appearance.animations.durations.small
				}

				PropertyAnimation {
					target: clockContainer
					properties: "opacity,scale"

					from: 0
					to: 1
					duration: Appearance.animations.durations.expressiveDefaultSpatial
					easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
				}

				PropertyAnimation {
					target: inputContainer
					properties: "opacity,scale"

					from: 0
					to: 1
					duration: Appearance.animations.durations.normal
					easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
				}

				PropertyAnimation {
					target: sessionContainer
					properties: "opacity,scale"

					from: 0
					to: 1
					duration: Appearance.animations.durations.normal
					easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
				}
			}
		}
	}

	Connections {
		target: root.pam
		enabled: root.pam !== null

		function onShowFailureChanged() {
			if (root.pam.showFailure)
				errorShakeAnimation.start();
		}
	}

	SequentialAnimation {
		id: errorShakeAnimation

		PropertyAnimation {
			target: inputContainer
			property: "anchors.horizontalCenterOffset"
			from: 0
			to: -8
			duration: Appearance.animations.durations.small * 0.8
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
		}
		PropertyAnimation {
			target: inputContainer
			property: "anchors.horizontalCenterOffset"
			from: -8
			to: 8
			duration: Appearance.animations.durations.small * 0.8
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.standardAccel
		}
		PropertyAnimation {
			target: inputContainer
			property: "anchors.horizontalCenterOffset"
			from: 8
			to: -4
			duration: Appearance.animations.durations.small * 0.8
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.standardAccel
		}
		PropertyAnimation {
			target: inputContainer
			property: "anchors.horizontalCenterOffset"
			from: -4
			to: 0
			duration: Appearance.animations.durations.small * 0.8
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
		}
	}
}
