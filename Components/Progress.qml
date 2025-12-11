import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services

StyledRect {
    id: root

    property bool condition: false
    property real waveAmplitude: 0
    property real waveFrequency: 8
    property real waveAnimationPhase: 0
    property color trackColor: Colours.m3Colors.m3SurfaceContainerHighest
    property color indicatorColor: Colours.m3Colors.m3Primary
    property real cornerRadius: 2

    Layout.fillWidth: true
    height: 4
    visible: condition
    color: "transparent"

    StyledRect {
        anchors.fill: parent
        color: root.trackColor
        radius: root.cornerRadius
    }

    Canvas {
        id: indicatorCanvas
        anchors.fill: parent
        antialiasing: true

        property real barPosition: 0
        property real barWidth: parent.width * 0.35

        function drawRoundedRect(ctx, x, y, width, height, radius) {
            ctx.beginPath();
            ctx.moveTo(x + radius, y);
            ctx.lineTo(x + width - radius, y);
            ctx.arcTo(x + width, y, x + width, y + radius, radius);
            ctx.lineTo(x + width, y + height - radius);
            ctx.arcTo(x + width, y + height, x + width - radius, y + height, radius);
            ctx.lineTo(x + radius, y + height);
            ctx.arcTo(x, y + height, x, y + height - radius, radius);
            ctx.lineTo(x, y + radius);
            ctx.arcTo(x, y, x + radius, y, radius);
            ctx.closePath();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (!root.visible)
                return;
            var startX = barPosition;
            var endX = barPosition + barWidth;

            if (startX > width)
                return;
            if (endX < 0)
                return;
            startX = Math.max(0, startX);
            endX = Math.min(width, endX);

            var drawWidth = endX - startX;
            if (drawWidth <= 0)
                return;
            ctx.fillStyle = root.indicatorColor;

            if (root.waveAmplitude > 0) {
                var steps = Math.max(Math.floor(drawWidth / 2), 20);
                ctx.beginPath();
                ctx.moveTo(startX, height / 2);

                for (var i = 0; i <= steps; i++) {
                    var progress = i / steps;
                    var x = startX + drawWidth * progress;
                    var normalizedPos = x / width;
                    var waveOffset = Math.sin(normalizedPos * Math.PI * 2 * root.waveFrequency + root.waveAnimationPhase) * root.waveAmplitude;
                    var y = height / 2 + waveOffset;

                    if (i === 0) {
                        ctx.moveTo(x, y - height / 2);
                    }
                    ctx.lineTo(x, y + height / 2);
                }

                for (var j = steps; j >= 0; j--) {
                    var progress2 = j / steps;
                    var x2 = startX + drawWidth * progress2;
                    var normalizedPos2 = x2 / width;
                    var waveOffset2 = Math.sin(normalizedPos2 * Math.PI * 2 * root.waveFrequency + root.waveAnimationPhase) * root.waveAmplitude;
                    var y2 = height / 2 + waveOffset2;
                    ctx.lineTo(x2, y2 - height / 2);
                }

                ctx.closePath();
                ctx.fill();
            } else {
                drawRoundedRect(ctx, startX, 0, drawWidth, height, root.cornerRadius);
                ctx.fill();
            }
        }

        Connections {
            target: root

            function onWaveAnimationPhaseChanged() {
                indicatorCanvas.requestPaint();
            }
        }

        SequentialAnimation {
            id: loadingAnimation

            loops: Animation.Infinite
            running: root.visible

            ParallelAnimation {
                NAnim {
                    target: indicatorCanvas
                    property: "barWidth"
                    from: root.width * 0.0
                    to: root.width * 0.75
                }
                NAnim {
                    target: indicatorCanvas
                    property: "barPosition"
                    from: 0
                    to: root.width * 0.25
                }
            }

            ParallelAnimation {
                NAnim {
                    target: indicatorCanvas
                    property: "barWidth"
                    from: root.width * 0.75
                    to: root.width * 0.0
                }
                NAnim {
                    target: indicatorCanvas
                    property: "barPosition"
                    from: root.width * 0.25
                    to: root.width
                }
            }
        }

        onBarPositionChanged: requestPaint()
        onBarWidthChanged: requestPaint()
    }
}
