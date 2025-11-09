pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

StyledRect {
	id: root

	required property int state
	required property real scaleFactor

	signal tabClicked(int index)

	Layout.fillWidth: true
	Layout.preferredHeight: 60
	color: Colors.colors.surface_container

	RowLayout {
		anchors.centerIn: parent
		spacing: 15
		width: parent.width * 0.95

		Repeater {
			id: tabRepeater

			model: [
				{
					title: "Settings",
					icon: "settings",
					index: 0
				},
				{
					title: "Volumes",
					icon: "speaker",
					index: 1
				},
				{
					title: "Performance",
					icon: "speed",
					index: 2
				},
				{
					title: "Weather",
					icon: "cloud",
					index: 3
				}
			]

			StyledButton {
				id: settingButton

				required property var modelData
				required property int index

				buttonTitle: modelData.title
				Layout.fillWidth: true
				highlighted: root.state === modelData.index
				flat: root.state !== modelData.index
				onClicked: root.tabClicked(settingButton.index)

				background: Rectangle {
					color: root.state === settingButton.index ? Colors.colors.primary : Colors.colors.surface_container
					radius: Appearance.rounding.small
				}

				contentItem: RowLayout {
					anchors.centerIn: parent
					spacing: Appearance.spacing.small

					MatIcon {
						icon: settingButton.modelData.icon
						color: root.state === settingButton.index ? Colors.colors.on_primary : Colors.colors.on_surface_variant
						font.pixelSize: Appearance.fonts.large * root.scaleFactor + 10
					}

					StyledText {
						text: settingButton.modelData.title
						color: root.state === settingButton.index ? Colors.colors.on_primary : Colors.colors.on_surface_variant
						font.pixelSize: Appearance.fonts.large * root.scaleFactor
						elide: Text.ElideRight
					}
				}
			}
		}
	}
}
