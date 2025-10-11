import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Widgets

Loader {
	active: root.isBarOpen
	asynchronous: true

 	sourceComponent: RowLayout {
		anchors.fill: parent
		anchors.leftMargin: Appearance.margin.small
		spacing: Appearance.spacing.normal

		OsText {
			Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
		}

		Workspaces {
			Layout.alignment: Qt.AlignCenter
		}

		WorkspaceName {
			Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
		}

		Item {
			Layout.fillWidth: true
		}
	}
}
