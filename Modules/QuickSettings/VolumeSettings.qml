import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire

import qs.Data
import qs.Widgets
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
				color: Colors.colors.outline
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

					height: 35

					delegate: ItemDelegate {
						id: itemDelegate

						required property var modelData
						required property int index

						width: 350
						height: modelData.available === "yes" ? implicitHeight : 0
						visible: modelData.available === "yes"
						text: modelData.readable
						highlighted: profilesComboBox.highlightedIndex === index
						enabled: modelData.available === "yes"
					}

					indicator: Canvas {
						id: canvas
						x: profilesComboBox.width - width - profilesComboBox.rightPadding
						y: profilesComboBox.topPadding + (profilesComboBox.availableHeight - height) / 2
						width: 12
						height: 8
						contextType: "2d"

						Connections {
							target: profilesComboBox
							function onPressedChanged() {
								canvas.requestPaint();
							}
						}

						onPaint: {
							context.reset();
							context.moveTo(0, 0);
							context.lineTo(width, 0);
							context.lineTo(width / 2, height);
							context.closePath();
							context.fillStyle = profilesComboBox.pressed ? Colors.withAlpha(Colors.colors.primary, 0.1) : Colors.colors.primary;
							context.fill();
						}
					}

					popup: Popup {
						y: profilesComboBox.height - 1
						width: 350
						implicitHeight: contentItem.implicitHeight + 2
						height: Math.min(implicitHeight, profilesComboBox.Window.height - topMargin - bottomMargin)
						padding: 1

						contentItem: ListView {
							clip: true
							implicitHeight: contentHeight
							model: profilesComboBox.popup.visible ? profilesComboBox.delegateModel : null
							currentIndex: profilesComboBox.highlightedIndex
							z: 2
							ScrollIndicator.vertical: ScrollIndicator {}
						}
					}

					onActivated: function (index) {
						const profile = AudioProfiles.models[index];
						if (profile && profile.available === "yes") {
							console.log(AudioProfiles.idPipewire + " " + profile.index);
							Quickshell.execDetached({
								command: ["sh", "-c", `pw-cli set-param ${AudioProfiles.idPipewire} Profile '{ \"index\": ${profile.index}}'`]
							});
							AudioProfiles.activeProfileIndex = profile.index;
						}
					}
				}
			}
		}
	}
}
