import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.Data
import qs.Helpers
import qs.Components

LazyLoader {
	id: volumeOsdLoader

	active: false
	component: PanelWindow {
		id: root

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

		property string icon: Audio.getIcon(root.node)
		property PwNode node: Pipewire.defaultAudioSink

		StyledRect {
			anchors.fill: parent
			radius: height / 2
			color: Colors.colors.background

			RowLayout {
				anchors {
					fill: parent
					leftMargin: 10
					rightMargin: 15
				}

				MatIcon {
					color: Colors.colors.on_background
					icon: root.icon
					Layout.alignment: Qt.AlignVCenter
					font.pixelSize: Appearance.fonts.extraLarge * 1.2
				}

				StyledText {
					text: Math.round(Pipewire.defaultAudioSink?.audio.volume * 100)
					color: Colors.colors.on_background
					font.pixelSize: Appearance.fonts.large
				}

				StyledRect {
					Layout.fillWidth: true

					implicitHeight: 10
					radius: 20
					color: Colors.colors.secondary_container

					StyledRect {
						anchors {
							left: parent.left
							top: parent.top
							bottom: parent.bottom
						}

						color: Colors.colors.primary

						implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
						radius: parent.radius
					}
				}
			}
		}
	}
}
