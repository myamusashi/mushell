import QtQuick
import QtQuick.Controls

import qs.Components
import qs.Configs
import qs.Services

Slider {
    id: slider

    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3SecondaryContainer
    property int waveAmplitude: 3
    property real waveFrequency: 10
    property int separatorWidth: 8
    property int separatorHeight: 4
    property real waveAnimationPhase: 1
    property bool enableWave: true
    property real waveTransition: 1.0

    snapMode: Slider.NoSnap

    Behavior on waveTransition {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    onEnableWaveChanged: waveTransition = enableWave ? 1.0 : 0.0

    NumberAnimation on waveAnimationPhase {
        from: 0
        to: Math.PI * 2 
        duration: 2000
        loops: Animation.Infinite
        running: slider.enableWave
    }

    background: Item {
        id: bg

        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: slider.availableWidth
        height: slider.height || 10
        readonly property real trackStartX: 0
        readonly property real trackEndX: width
        readonly property real trackWidth: trackEndX - trackStartX
        readonly property real normalizedValue: slider.visualPosition

        Canvas {
            id: wavyCanvas

            anchors.fill: parent
            antialiasing: true
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var trackStartX = bg.trackStartX;
                var trackWidth = bg.trackWidth;
                var normalizedValue = bg.normalizedValue;
                var activeWidth = trackWidth * normalizedValue;
                var gapOffset = slider.separatorWidth / 2;
                activeWidth = Math.max(0, activeWidth - gapOffset);
                ctx.strokeStyle = slider.activeColor;
                ctx.lineWidth = 4;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.beginPath();
                ctx.moveTo(trackStartX, height / 2);

                var steps = Math.max(Math.floor(activeWidth / 3), 30);
                var effectiveAmplitude = slider.waveAmplitude * slider.waveTransition;

                for (var i = 1; i <= steps; i++) {
                    var progress = i / steps;
                    var currentProgress = (progress * activeWidth) / trackWidth;
                    var x = trackStartX + trackWidth * currentProgress;
                    var waveOffset = Math.sin(currentProgress * Math.PI * 2 * slider.waveFrequency + slider.waveAnimationPhase) * effectiveAmplitude;
                    var y = height / 2 + waveOffset;
                    ctx.lineTo(x, y);
                }

                ctx.stroke();
            }
            Connections {
                target: slider
                function onVisualPositionChanged() {
                    wavyCanvas.requestPaint();
                }
                function onWaveAnimationPhaseChanged() {
                    wavyCanvas.requestPaint();
                }
                function onWaveTransitionChanged() {
                    wavyCanvas.requestPaint();
                }
            }
        }
        Canvas {
            id: inactiveCanvas

            anchors.fill: parent
            antialiasing: true
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var trackStartX = bg.trackStartX;
                var trackWidth = bg.trackWidth;
                var normalizedValue = bg.normalizedValue;
                var gapOffset = slider.separatorWidth / 2;
                var inactiveStartPos = normalizedValue + (gapOffset / trackWidth);
                var inactiveWidth = trackWidth * (1 - inactiveStartPos);
                if (inactiveWidth <= 0 || inactiveStartPos >= 1)
                    return;
                ctx.strokeStyle = slider.inactiveColor;
                ctx.lineWidth = 4;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                var startX = trackStartX + trackWidth * inactiveStartPos;
                var startY = height / 2;
                ctx.beginPath();
                ctx.moveTo(startX, startY);
                ctx.lineTo(trackStartX + trackWidth, height / 2);
                ctx.stroke();
            }
            Connections {
                target: slider

                function onVisualPositionChanged() {
                    inactiveCanvas.requestPaint();
                }
            }
        }
    }
    handle: Rectangle {
        id: handleRect

        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: 20
        height: 20
        radius: Appearance.rounding.full
        color: slider.activeColor
        opacity: slider.hovered ? 1 : 0
        scale: slider.pressed ? 1.3 : 1
        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }
}
