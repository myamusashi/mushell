import qs.Widgets
import qs.Data
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

Item {
	RowLayout {
		anchors.fill: parent
		anchors.rightMargin: 8
		layoutDirection: Qt.RightToLeft
		spacing: Appearance.spacing.small

		Clock {
			Layout.alignment: Qt.AlignVCenter
			Layout.maximumWidth: implicitWidth
		}
		Tray {
			Layout.alignment: Qt.AlignVCenter
			parentWindow: root
			parentScreen: root.modelData
		}
		PowerProfiles {
			Layout.alignment: Qt.AlignVCenter
			Layout.maximumWidth: implicitWidth
		}
		Sound {
			Layout.alignment: Qt.AlignVCenter
			Layout.maximumWidth: implicitWidth
		}
		Sound {
			Layout.alignment: Qt.AlignVCenter
			Layout.maximumWidth: implicitWidth
			node: Pipewire.defaultAudioSource
		}
		Battery {
			Layout.alignment: Qt.AlignVCenter
			Layout.maximumWidth: implicitWidth
		}

		// Item {
		// 	Layout.fillWidth: true
		// }
	}
}
