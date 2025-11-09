import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire

import qs.Data
import qs.Widgets

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
				node: Pipewire.defaultAudioSink
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
					node: modelData.source
				}
			}
		}
	}
}
