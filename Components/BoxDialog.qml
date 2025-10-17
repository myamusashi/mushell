pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	id: root

	required property bool isBoxShow
	required property string header
	required property string body

	active: isBoxShow
	sourceComponent: StyledRect {
		anchors.centerIn: parent

		implicitWidth: 600
		implicitHeight: 400

		color: Colors.colors.background

		ColumnLayout {
			anchors.centerIn: parent

			StyledText {
				id: headerText

				text: root.header
				color: Colors.colors.on_background
				elide: Qt.ElideMiddle
				font.pixelSize: Appearance.fonts.large
			}

			StyledText {
				id: bodyText

				text: root.body
				color: Colors.colors.on_background
				font.pixelSize: Appearance.fonts.medium

				elide: Qt.ElideRight
				wrapMode: Qt.TextWordWrap
			}
		}
	}
}
