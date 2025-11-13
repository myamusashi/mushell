import QtQuick

import qs.Data
import qs.Components

StyledRect {
	id: root

	color: "transparent"
	required property real value
	property string text
	property real size

	property real textPadding: 20
	property real minSize: 120 + size

	TextMetrics {
		id: textMetrics
		text: root.text
		font.pixelSize: 16
		font.bold: true
	}

	width: Math.max(minSize, Math.max(textMetrics.width, textMetrics.height) + textPadding * 4)
	height: width

	Canvas {
		id: canvas
		anchors.fill: parent
		onPaint: {
			var ctx = getContext("2d");
			var centerX = width / 2;
			var centerY = height / 2;
			var radius = Math.min(width, height) / 2 - 10;

			ctx.clearRect(0, 0, width, height);

			ctx.beginPath();
			ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
			ctx.strokeStyle = Themes.colors.secondary_container;
			ctx.lineWidth = 8;
			ctx.stroke();

			ctx.beginPath();
			var startAngle = -Math.PI / 2;
			var endAngle = startAngle + (root.value / 100) * 2 * Math.PI;
			ctx.arc(centerX, centerY, radius, startAngle, endAngle);
			ctx.strokeStyle = root.value > 80 ? Themes.colors.error : root.value > 60
												? Themes.colors.tertiary : Themes.colors.primary;
			ctx.lineWidth = 8;
			ctx.lineCap = "round";
			ctx.stroke();
		}
	}

	Timer {
		id: updateTimer

		interval: 500
		repeat: true
		running: true
		onTriggered: {
			canvas.requestPaint();
		}
	}

	StyledText {
		id: textStatus

		anchors.centerIn: parent
		text: root.text
		font.pixelSize: Math.max(12, Math.min(24, root.width / 6))
		font.bold: true
		color: Themes.colors.on_surface
		horizontalAlignment: Text.AlignHCenter
		verticalAlignment: Text.AlignVCenter
		wrapMode: Text.WordWrap
		width: parent.width - root.textPadding * 2
	}
}
