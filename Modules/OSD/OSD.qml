pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
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

	Timer {
		id: hideOSDTimer

		interval: 2000
		onTriggered: root.isVolumeOSDShow = false
	}

	LazyLoader {
		id: osdLoader

		activeAsync: root.isVolumeOSDShow

		component: PanelWindow {
			required property ShellScreen screen

			anchors {
				bottom: true
			}

			WlrLayershell.namespace: "shell:osd"
			screen: screen
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

				RowLayout {
					anchors {
						fill: parent
						leftMargin: 10
						rightMargin: 15
					}

					MatIcon {
						color: Appearance.colors.on_background
						icon: root.icon
						Layout.alignment: Qt.AlignVCenter
						font.pixelSize: Appearance.fonts.extraLarge * 1.2
					}

					Rectangle {
						Layout.fillWidth: true

						implicitHeight: 10
						radius: 20
						color: Appearance.colors.withAlpha(Appearance.colors.primary, 0.3)

						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}

							color: Appearance.colors.primary

							implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
							radius: parent.radius
						}
					}
				}
			}
		}
	}
}
