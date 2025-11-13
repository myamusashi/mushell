import QtQuick
import QtQuick.Layouts

Item {
	anchors.fill: parent

	ColumnLayout {
		id: settings
		anchors.fill: parent
		spacing: 10

		property alias wifiList: wifiList

		GridLayout {
			Layout.fillWidth: true
			Layout.margins: 10
			columns: 2
			rowSpacing: 10
			columnSpacing: 10

			BatteryInfoCard {
				Layout.fillWidth: true
				Layout.preferredHeight: 120
			}

			NetworkInfoColumn {
				Layout.fillWidth: true
				Layout.preferredHeight: 120
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			spacing: 10

			PowerProfileButtons {
				Layout.fillWidth: true
			}

			BrightnessControls {
				Layout.fillWidth: true
			}

			Widgets {
				Layout.fillWidth: true
			}
		}

		Item {
			Layout.fillHeight: true
		}
	}

	WifiList {
		id: wifiList
		anchors.fill: parent
	}
}
