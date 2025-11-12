import QtQuick
import QtQuick.Layouts

import "Settings"

ColumnLayout {
	id: settings

	anchors.fill: parent
	spacing: 15

	property alias wifiList: wifiList

	RowLayout {
		Layout.fillWidth: true
		Layout.fillHeight: true

		BatteryInfoCard {
			Layout.fillHeight: true
			Layout.fillWidth: true
			Layout.margins: 15
		}

		NetworkInfoColumn {
			Layout.fillHeight: true
			Layout.fillWidth: true
			Layout.margins: 15
		}
	}

	PowerProfileButtons {
		Layout.fillWidth: true
		Layout.rightMargin: 15
		Layout.leftMargin: 15
	}

	BrightnessControls {
		Layout.fillWidth: true
		Layout.rightMargin: 15
		Layout.leftMargin: 15
	}

	Widgets {
		Layout.fillWidth: true
		Layout.rightMargin: 15
		Layout.leftMargin: 15
	}

	Item {
		Layout.fillHeight: true
	}

	WifiList {
		id: wifiList

		Layout.fillWidth: true
		Layout.fillHeight: true
	}
}
