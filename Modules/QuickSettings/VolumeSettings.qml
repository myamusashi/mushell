pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire

import qs.Data
import qs.Widgets
import qs.Helpers
import qs.Components

ScrollView {
	anchors.fill: parent
	contentWidth: availableWidth
	clip: true

	RowLayout {
		anchors.fill: parent
		Layout.margins: 15
		spacing: 20

		ColumnLayout {
			Layout.margins: 10
			Layout.alignment: Qt.AlignTop

			PwNodeLinkTracker {
				id: linkTracker
				node: Pipewire.defaultAudioSink
			}

			MixerEntry {
				useCustomProperties: true
				node: Pipewire.defaultAudioSink

				customProperty: audioProfilesComboBox
			}

			Rectangle {
				Layout.fillWidth: true
				color: Themes.colors.outline
				implicitHeight: 1
			}

			Repeater {
				model: linkTracker.linkGroups

				MixerEntry {
					required property PwLinkGroup modelData
					useCustomProperties: false
					node: modelData.source
				}
			}

			Component {
				id: audioProfilesComboBox

				ComboBox {
					id: profilesComboBox

					model: AudioProfiles.models
					textRole: "readable"
					implicitWidth: 350
					currentIndex: {
						for (let i = 0; i < AudioProfiles.models.length; i++) {
							if (AudioProfiles.models[i].index === AudioProfiles.activeProfileIndex) {
								return i;
							}
						}
						return -1;
					}
					height: contentItem.implicitHeight * 2

					MArea {
						id: mArea

						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						z: -1
					}

					background: Rectangle {
						implicitWidth: 350
						radius: 4
						color: Themes.withAlpha(Themes.colors.surface_container, 0.9)

						Rectangle {
							x: 12
							y: 0
							height: 2
							color: Themes.colors.on_background
							visible: true
						}
					}

					contentItem: StyledText {
						leftPadding: Appearance.padding.normal
						rightPadding: profilesComboBox.indicator.width + profilesComboBox.spacing
						text: profilesComboBox.displayText
						color: Themes.colors.on_background
						verticalAlignment: Text.AlignVCenter
						elide: Text.ElideRight
					}

					delegate: ItemDelegate {
						id: itemDelegate

						required property var modelData
						required property int index
						width: profilesComboBox.width
						padding: Appearance.padding.normal

						background: StyledRect {
							color: itemDelegate.highlighted ? Themes.colors.primary : itemDelegate.hovered
															  ? itemDelegate.modelData.available !== "yes" ? "transparent" : Themes.withAlpha(
																												 Themes.colors.primary, 0.1) : "transparent"
						}

						contentItem: StyledText {
							text: itemDelegate.modelData.readable
							color: itemDelegate.modelData.available !== "yes" ? Themes.colors.outline_variant :
																				Themes.colors.on_background
							verticalAlignment: Text.AlignVCenter
							elide: Text.ElideRight
						}

						enabled: modelData.available === "yes"
					}

					indicator: Item {
						x: profilesComboBox.width - width - 12
						y: profilesComboBox.topPadding + (profilesComboBox.availableHeight - height) / 2
						width: 24
						height: 24

						Canvas {
							id: canvas

							anchors.centerIn: parent
							width: 10
							height: 5
							contextType: "2d"

							Connections {
								target: profilesComboBox
								function onPressedChanged() {
									canvas.requestPaint();
								}
							}

							Component.onCompleted: requestPaint()

							onPaint: {
								context.reset();
								context.moveTo(0, 0);
								context.lineTo(width, 0);
								context.lineTo(width / 2, height);
								context.closePath();
								context.fillStyle = Themes.colors.on_background;
								context.fill();
							}
						}

						StyledRect {
							anchors.centerIn: parent
							width: 40
							height: 40
							radius: Appearance.rounding.large
							color: Themes.colors.primary
							opacity: profilesComboBox.pressed ? 0.12 : profilesComboBox.hovered ? 0.08 : 0

							Behavior on opacity {
								NumbAnim {}
							}
						}
					}

					popup: Popup {
						y: profilesComboBox.height
						width: profilesComboBox.width
						implicitHeight: contentItem.implicitHeight
						height: Math.min(implicitHeight, 250)
						padding: Appearance.padding.normal

						background: StyledRect {
							color: Themes.colors.surface_container_low
							radius: Appearance.rounding.small
						}

						contentItem: ListView {
							clip: true
							implicitHeight: contentHeight - 5
							model: profilesComboBox.popup.visible ? profilesComboBox.delegateModel : null
							currentIndex: profilesComboBox.highlightedIndex

							ScrollIndicator.vertical: ScrollIndicator {
								contentItem: StyledRect {
									implicitWidth: 4
									radius: Appearance.rounding.small
									color: Themes.withAlpha(Themes.colors.primary, 0.1)
								}
							}
						}

						enter: Transition {
							NumbAnim {
								property: "opacity"
								from: 0.0
								to: 1.0
							}
							NumbAnim {
								property: "scale"
								from: 0.9
								to: 1.0
							}
						}

						exit: Transition {
							NumbAnim {
								property: "scale"
								from: 1.0
								to: 0.9
							}
							NumbAnim {
								property: "opacity"
								from: 1.0
								to: 0.0
							}
						}
					}

					onActivated: index => {
						const profile = AudioProfiles.models[index];
						if (profile && profile.available === "yes") {
							Quickshell.execDetached({
														command: ["sh", "-c", `pw-cli set-param 
${AudioProfiles.idPipewire} Profile '{ \"index\": ${profile.index}}'`]
													});
							AudioProfiles.activeProfileIndex = profile.index;
						}
					}
				}
			}
		}
	}
}
