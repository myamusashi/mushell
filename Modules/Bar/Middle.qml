import QtQuick
import QtQuick.Layouts
import qs.Widgets

Loader {
	active: root.isBarOpen
	asynchronous: true

	sourceComponent: RowLayout {
		anchors.centerIn: parent

		Mpris {
			Layout.alignment: Qt.AlignCenter
		}

		Item {
			Layout.preferredWidth: 250
		}
	}
}
