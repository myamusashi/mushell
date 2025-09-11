import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Data

ColumnLayout {
	id: root

	property var currentDate: new Date()
	
	function getDayName(index) {
		const days = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
		return days[index];
	}
	
	function getMonthName(index) {
		const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Des"];
		return months[index];
	}
	
	Timer {
		interval: 1000
		repeat: true
		running: true
		onTriggered: root.currentDate = new Date()
	}
	
	Label {
		font.pixelSize: Appearance.fonts.extraLarge * 4
		font.family: Appearance.fonts.family_Clock
		font.bold: true
		color: Appearance.colors.primary
		renderType: Text.NativeRendering
		text: {
			const hours = root.currentDate.getHours().toString().padStart(2, '0');
			const minutes = root.currentDate.getMinutes().toString().padStart(2, '0');
			return `${hours}\n${minutes}`;
		}
		Layout.alignment: Qt.AlignHCenter
	}
	
	Label {
		font.pixelSize: Appearance.fonts.medium * 2
		font.family: Appearance.fonts.family_Mono
		color: Appearance.colors.primary
		renderType: Text.NativeRendering
		text: root.getDayName(root.currentDate.getDay())
		Layout.alignment: Qt.AlignHCenter
	}
	
	Label {
		font.pixelSize: Appearance.fonts.medium * 3.5
		font.family: Appearance.fonts.family_Sans
		color: Appearance.colors.primary
		renderType: Text.NativeRendering
		text: `${root.currentDate.getDate()} ${root.getMonthName(root.currentDate.getMonth())}`
		Layout.alignment: Qt.AlignHCenter
	}
}
