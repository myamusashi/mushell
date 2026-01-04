import QtQuick

import qs.Configs
import qs.Components

import "../Submodules/rounded-polygon-qmljs/shapes/morph.js" as Morph

Canvas {
    id: root

    property color color: "#685496"
    property var roundedPolygon: null
    property bool polygonIsNormalized: true

    // Internals: size
    implicitWidth: roundedPolygon[2] - roundedPolygon[0]
    implicitHeight: roundedPolygon[3] - roundedPolygon[1]

    // Internals: anim
    property var prevRoundedPolygon: null
    property double progress: 1
    property var morph: new Morph.Morph(roundedPolygon, roundedPolygon)
    property Animation animation: NAnim {
        duration: Appearance.animations.durations.expressiveFastSpatial
        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
    }

    onRoundedPolygonChanged: {
        delete root.morph;
        root.morph = new Morph.Morph(root.prevRoundedPolygon ?? root.roundedPolygon, root.roundedPolygon);
        morphBehavior.enabled = false;
        root.progress = 0;
        morphBehavior.enabled = true;
        root.progress = 1;
        root.prevRoundedPolygon = root.roundedPolygon;
    }

    Behavior on progress {
        id: morphBehavior

        animation: root.animation
    }

    onProgressChanged: requestPaint()
    onColorChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d");
        ctx.fillStyle = root.color;
        ctx.clearRect(0, 0, width, height);
        if (!root.morph)
            return;
        const cubics = root.morph.asCubics(root.progress);
        if (cubics.length === 0)
            return;
        const size = Math.min(root.width, root.height);
        const offsetX = root.width / 2 - size / 2;
        const offsetY = root.height / 2 - size / 2;

        ctx.save();
        ctx.translate(offsetX, offsetY);
        if (root.polygonIsNormalized)
            ctx.scale(size, size);

        ctx.beginPath();
        ctx.moveTo(cubics[0].anchor0X, cubics[0].anchor0Y);
        for (const cubic of cubics)
            ctx.bezierCurveTo(cubic.control0X, cubic.control0Y, cubic.control1X, cubic.control1Y, cubic.anchor1X, cubic.anchor1Y);

        ctx.closePath();
        ctx.fill();
        ctx.restore();
    }
}
