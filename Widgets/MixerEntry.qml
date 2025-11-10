import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire

import qs.Data
import qs.Components

ColumnLayout {
	id: root

	required property bool useCustomProperties
	property Component customProperty
	required property PwNode node

	PwObjectTracker {
		objects: [root.node]
	}

	RowLayout {
		Image {
			visible: source !== ""
			source: {
				const icon = root.node.properties["application.icon-name"] ?? "audio-volume-high-symbolic";
				return `image://icon/${icon}`;
			}

			sourceSize.width: 20
			sourceSize.height: 20
		}

		Loader {
			active: true

			sourceComponent: root.useCustomProperties ? root.customProperty : defaultNode
		}

		Component {
			id: defaultNode
			
			StyledLabel {
				text: {
					const app = root.node.properties["application.name"] ?? (root.node.description != "" ? root.node.description : root.node.name);
					const media = root.node.properties["media.name"];
					return media != undefined ? `${app} - ${media}` : app;
				}
				elide: Text.ElideRight
				wrapMode: Text.Wrap
				Layout.fillWidth: true
			}
		}

		StyledButton {
			buttonTitle: root.node.audio.muted ? "unmute" : "mute"
			onClicked: root.node.audio.muted = !root.node.audio.muted
			buttonTextColor: Colors.colors.on_surface
			buttonHoverTextColor: Colors.withAlpha(Colors.colors.on_surface, 0.12)
			buttonPressedTextColor: Colors.withAlpha(Colors.colors.on_surface, 0.08)
			buttonColor: Colors.colors.surface_container
			buttonHoverColor: Colors.withAlpha(Colors.colors.surface_container, 0.12)
			buttonPressedColor: Colors.withAlpha(Colors.colors.surface_container, 0.08)
			isButtonFullRound: false
			backgroundRounding: 15
		}
	}

	RowLayout {
		StyledLabel {
			Layout.preferredWidth: 50
			text: `${Math.floor(root.node.audio.volume * 100)}%`
		}

		StyledSlide {
			Layout.fillWidth: true
			Layout.preferredHeight: 44
			value: root.node.audio.volume
			onValueChanged: root.node.audio.volume = value
		}
	}
}
