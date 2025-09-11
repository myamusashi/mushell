import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Data

// Middle.qml
Item {
	RowLayout {
		anchors.centerIn: parent
		spacing: Appearance.spacing.small

		Mpris {
			Layout.alignment: Qt.AlignCenter
		}

		Item {
			Layout.preferredWidth: 250
		}
	}
}
