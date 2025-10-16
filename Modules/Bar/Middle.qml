import QtQuick
import QtQuick.Layouts
import qs.Widgets

Loader {
	active: root.isBarOpen
	asynchronous: true

	sourceComponent: RowLayout {
		Layout.alignment: Qt.AlignCenter

		Mpris {
			Layout.alignment: Qt.AlignCenter
		}
	}
}
