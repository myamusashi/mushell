import qs.Widgets
import qs.Data
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

Item {
	RowLayout {
		anchors.fill: parent
		anchors.rightMargin: Appearance.margin.small
		layoutDirection: Qt.RightToLeft
		spacing: Appearance.spacing.normal

		Clock {
			Layout.alignment: Qt.AlignVCenter
			Layout.maximumWidth: implicitWidth
		}
		Tray {
			Layout.alignment: Qt.AlignVCenter
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
	}
}
