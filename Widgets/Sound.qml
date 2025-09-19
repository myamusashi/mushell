import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Data
import qs.Helpers
import qs.Components
import qs.Windows

Rectangle {
	id: root

	property string icon: Audio.getIcon(root.node)
	property PwNode node: Pipewire.defaultAudioSink

	Layout.fillHeight: true
	// color: Appearance.colors.withAlpha(Appearance.colors.background, 0.79)
	color: "transparent"
	implicitWidth: container.width
	radius: 5

	Behavior on implicitWidth {
		NumbAnim {}
	}

	PwObjectTracker {
		objects: [root.node]
	}

	Dots {
		id: container

		spacing: 5

		MatIcon {
			color: Appearance.colors.on_background
			icon: root.icon
			Layout.alignment: Qt.AlignVCenter
			font.pixelSize: Appearance.fonts.large * 1.2
		}

		StyledText {
			color: Appearance.colors.on_background
			text: (root.node.audio.volume * 100).toFixed(0) + "%"
			Layout.alignment: Qt.AlignVCenter
			font.pixelSize: Appearance.fonts.medium
		}
	}

	Mixer {
		id: mixer
	}

	MouseArea {
		acceptedButtons: Qt.MiddleButton | Qt.LeftButton
		anchors.fill: parent

		onClicked: mevent => {
			if (mevent.button === Qt.MiddleButton) {
				Audio.toggleMute(root.node);
			} else if (mevent.button === Qt.LeftButton) {
				mixer.visible = !mixer.visible;
			}
		}

		onWheel: mevent => Audio.wheelAction(mevent, root.node)
	}
}
