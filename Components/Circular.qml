import QtQuick

import qs.Components
import qs.Services

StyledRect {
    id: root

    required property real value

    readonly property real calculatedWidth: Math.max(minSize, Math.max(textMetrics.width, textMetrics.height) + textPadding * 4)

    property string text
    property real size
    property real textPadding: 20
    property real minSize: 120 + size

    width: calculatedWidth
    height: width

    TextMetrics {
        id: textMetrics

        text: root.text
        font.pixelSize: 16
        font.bold: true
    }

    Canvas {
        id: canvas

        anchors.fill: parent

        onValueChanged: requestPaint()

        renderStrategy: Canvas.Threaded
        renderTarget: Canvas.FramebufferObject

        property real value: root.value

        onPaint: {
            var ctx = getContext("2d");
            var centerX = width / 2;
            var centerY = height / 2;
            var radius = Math.min(width, height) / 2 - 10;

            ctx.clearRect(0, 0, width, height);

            // Background arc
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
            ctx.strokeStyle = Colours.m3Colors.m3OutlineVariant;
            ctx.lineWidth = 8;
            ctx.stroke();

            // Progress arc
            ctx.beginPath();
            var startAngle = -Math.PI / 2;
            var endAngle = startAngle + (value / 100) * 2 * Math.PI;
            ctx.arc(centerX, centerY, radius, startAngle, endAngle);

            // Color based on value
            ctx.strokeStyle = value > 80 ? Colours.m3Colors.m3Error : value > 60 ? Colours.m3Colors.m3Tertiary : Colours.m3Colors.m3Primary;
            ctx.lineWidth = 8;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }

    StyledText {
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Math.max(12, Math.min(24, root.width / 6))
        font.bold: true
        color: Colours.m3Colors.m3OnSurface
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        width: parent.width - root.textPadding * 2
    }
}
