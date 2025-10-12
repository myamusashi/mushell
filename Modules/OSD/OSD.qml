pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: root

	property bool isVolumeOSDShow: false
	property string icon: Audio.getIcon(root.node)
	property PwNode node: Pipewire.defaultAudioSink

	PwObjectTracker {
		objects: [Pipewire.defaultAudioSink]
	}

	Connections {
		target: Pipewire.defaultAudioSink?.audio
		function onVolumeChanged() {
			root.isVolumeOSDShow = true;
			hideOSDTimer.restart();
		}
	}

	// This is the easiest way to get lock state with a little bit performance concern
	Process {
		id: lockStateProcess

		running: true
		command: [`${Quickshell.shellDir}/Assets/lockState`]
	}

	property bool capsLockState: false
	property bool numLockState: false
	property bool isCapsLockOSDShow: false
	property bool isNumLockOSDShow: false

	FileView {
		id: capsLockStateFile

		path: Quickshell.env("HOME") + "/.cache/hyprlandKeyState/capslockState"
		watchChanges: true
		onFileChanged: {
			reload();
			let newState = text().trim() === "true";
			if (root.capsLockState !== newState) {
				root.capsLockState = newState;
				root.isCapsLockOSDShow = true;
				hideOSDTimer.restart();
			}
		}
	}

	FileView {
		id: numLockStateFile

		path: Quickshell.env("HOME") + "/.cache/hyprlandKeyState/numlockState"
		watchChanges: true
		onFileChanged: {
			reload();
			let newState = text().trim() === "true";
			if (root.numLockState !== newState) {
				root.numLockState = newState;
				root.isNumLockOSDShow = true;
				hideOSDTimer.restart();
			}
		}
	}

	Timer {
		id: hideOSDTimer

		interval: 2000
		onTriggered: {
			root.isVolumeOSDShow = false;
			root.isCapsLockOSDShow = false;
			root.isNumLockOSDShow = false;
		}
	}

	LazyLoader {
		id: volumeOsdLoader

		activeAsync: root.isVolumeOSDShow
		component: PanelWindow {
			anchors.bottom: true
			WlrLayershell.namespace: "shell:osd:volume"
			color: "transparent"
			exclusionMode: ExclusionMode.Ignore
			focusable: false
			implicitWidth: 350
			implicitHeight: 50
			exclusiveZone: 0
			margins.bottom: 30
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: height / 2
				color: Appearance.colors.background
				Volumes {}
			}
		}
	}

	LazyLoader {
		id: capsLockOsdLoader

		activeAsync: root.isCapsLockOSDShow
		component: PanelWindow {
			anchors.bottom: true
			WlrLayershell.namespace: "shell:osd:capslock"
			color: "transparent"
			exclusionMode: ExclusionMode.Ignore
			focusable: false
			implicitWidth: 350
			implicitHeight: 50
			exclusiveZone: 0
			margins.bottom: 90
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: height / 2
				color: Appearance.colors.background

				Row {
					anchors.centerIn: parent
					spacing: 10

					StyledText {
						text: "Caps Lock"
						color: Appearance.colors.on_background
						font.pixelSize: Appearance.fonts.large * 1.5
					}

					MatIcon {
						icon: root.capsLockState ? "lock" : "lock_open_right"
						color: root.capsLockState ? Appearance.colors.primary : Appearance.colors.tertiary
						font.pixelSize: Appearance.fonts.large * 1.5
					}
				}
			}
		}
	}

	LazyLoader {
		id: numLockOsdLoader

		activeAsync: root.isNumLockOSDShow
		component: PanelWindow {
			anchors.bottom: true
			WlrLayershell.namespace: "shell:osd:numlock"
			color: "transparent"
			exclusionMode: ExclusionMode.Ignore
			focusable: false
			implicitWidth: 350
			implicitHeight: 50
			exclusiveZone: 0
			margins.bottom: 150
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: height / 2
				color: Appearance.colors.background

				Row {
					anchors.centerIn: parent
					spacing: 10

					StyledText {
						text: "Num Lock"
						color: Appearance.colors.on_background
						font.pixelSize: Appearance.fonts.large * 1.5
					}

					MatIcon {
						icon: root.numLockState ? "lock" : "lock_open_right"
						color: root.numLockState ? Appearance.colors.primary : Appearance.colors.tertiary
						font.pixelSize: Appearance.fonts.large * 1.5
					}
				}
			}
		}
	}
}
