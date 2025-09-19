import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Data

Item {
	RowLayout {
		anchors.centerIn: parent

		Mpris {
			Layout.alignment: Qt.AlignCenter
		}

		Item {
			Layout.preferredWidth: 250
		}
	}
}
