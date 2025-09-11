import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Widgets

Item {
	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 8
		spacing: Appearance.spacing.small

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
