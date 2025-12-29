pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "../../../Submodules/rounded-polygon-qmljs/material-shapes.js" as MaterialShapes

ShapeCanvas {
    id: shape

    color: Colours.m3Colors.m3SurfaceContainer
    roundedPolygon: MaterialShapes.getSquare()
    onProgressChanged: requestPaint()

    Wave {
        anchors.fill: parent
        fillPercentage: 60
        z: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.normal
        z: 2

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop | Qt.AlignCenter
            Layout.topMargin: 5
            spacing: 0

            MaterialIcon {
                icon: "humidity_high"
                color: Colours.m3Colors.m3OnSurface
                font.pointSize: Appearance.fonts.size.large * 1.2
            }

            StyledText {
                text: "Humidity"
                color: Colours.m3Colors.m3OnSurface
                font.weight: Font.Bold
                font.pixelSize: Appearance.fonts.size.normal
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            text: Weather.humidity + "%"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
            font.weight: Font.Bold
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom | Qt.AlignCenter
            Layout.bottomMargin: 30
            spacing: Appearance.spacing.small

            Item {
                implicitHeight: 30
                implicitWidth: 30

                ShapeCanvas {
                    color: Colours.m3Colors.m3Primary
                    anchors.fill: parent
                    roundedPolygon: MaterialShapes.getCircle()
                    onProgressChanged: requestPaint()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: Weather.dewPoint.toFixed(0) + "°"
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.Bold
                    color: Colours.m3Colors.m3Surface
                }
            }

            StyledText {
                text: "Dew point"
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurface
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component Wave: Canvas {
        id: waveCanvas

        property real fillPercentage: 0
        property color waveColor: Colours.withAlpha(Colours.m3Colors.m3Primary, 0.4)

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var morph = shape.morph;
            if (!morph)
                return;

            var cubics = morph.asCubics(shape.progress);
            if (cubics.length === 0)
                return;

            var size = Math.min(width, height);
            var offsetX = width / 2 - size / 2;
            var offsetY = height / 2 - size / 2;

            ctx.save();

            ctx.translate(offsetX, offsetY);
            if (shape.polygonIsNormalized)
                ctx.scale(size, size);

            ctx.beginPath();
            ctx.moveTo(cubics[0].anchor0X, cubics[0].anchor0Y);
            for (var i = 0; i < cubics.length; i++) {
                var cubic = cubics[i];
                ctx.bezierCurveTo(cubic.control0X, cubic.control0Y, cubic.control1X, cubic.control1Y, cubic.anchor1X, cubic.anchor1Y);
            }
            ctx.closePath();
            ctx.clip();

            ctx.restore();
            ctx.save();
            ctx.clip();

            var fillHeight = height * (fillPercentage / 100);
            var waveY = height - fillHeight;

            ctx.fillStyle = waveColor;
            ctx.beginPath();

            var amplitude = 8;
            var wavelength = width / 1.2;

            ctx.moveTo(0, height);
            ctx.lineTo(0, waveY);

            var points = 50;

            for (var i = 0; i <= points; i++) {
                var x = (i / points) * width;
                var y = waveY + Math.sin((x / wavelength * Math.PI * 2)) * amplitude;

                if (i === 0) {
                    ctx.lineTo(x, y);
                } else {
                    var prevX = ((i - 1) / points) * width;
                    var prevY = waveY + Math.sin((prevX / wavelength * Math.PI * 2)) * amplitude;

                    var cpX = (prevX + x) / 2;
                    var cpY = (prevY + y) / 2;

                    ctx.quadraticCurveTo(prevX, prevY, cpX, cpY);
                }
            }

            ctx.lineTo(width, waveY + Math.sin((width / wavelength * Math.PI * 2)) * amplitude);
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fill();

            ctx.restore();
        }

        onFillPercentageChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: shape

            function onProgressChanged() {
                waveCanvas.requestPaint();
            }
        }
    }
}
