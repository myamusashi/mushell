import QtQuick
import Quickshell

import qs.Core.Configs
import qs.Services

import M3Shapes

Item {
    id: root

    anchors.centerIn: parent

    property bool status: false
    property double radius: 50
    property double padding: 50
    property double shapePadding: 12
    property var shapeGetters: [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval]
    property int shapeIndex: 0

    property real stiffness: 180
    property real dampingRatio: 0.6
    property real visibilityThreshold: 0.075
    property real rotationStep: 60

    readonly property real springDuration: {
        const wn = Math.sqrt(stiffness);
        const r = -dampingRatio * wn;
        const c = 1 / Math.sqrt(1 - dampingRatio * dampingRatio);
        return Math.log(visibilityThreshold / c) / r;
    }
    readonly property real springMaxVelocity: {
        const wn = Math.sqrt(stiffness);
        const factor = Math.exp(-dampingRatio * Math.acos(dampingRatio) / Math.sqrt(1 - dampingRatio * dampingRatio));
        return wn * factor;
    }
    property bool springSettled: true
    property real rotationStart: 0
    property real rotationTarget: 0

    function spring(t: real): var {
        const wn = Math.sqrt(stiffness);
        const za = dampingRatio * wn;

        const wd = wn * Math.sqrt(1 - dampingRatio * dampingRatio);
        const r = za / wd;
        const pos = 1 - Math.exp(-za * t) * (Math.cos(wd * t) + r * Math.sin(wd * t));
        const vel = Math.exp(-za * t) * (wn * wn / wd) * Math.sin(wd * t);

        return [pos, vel];
    }

    implicitWidth: 30
    implicitHeight: 30
    visible: status

    ElapsedTimer {
        id: timer
    }

    FrameAnimation {
        running: root.status && !root.springSettled
        onTriggered: {
            const t = timer.elapsed();

            if (t >= root.springDuration) {
                root.springSettled = true;
                shapeCanvas.morphProgress = 1;
                shapeCanvas.rotation = root.rotationTarget;
                shapeCanvas.scale = 1;
            } else {
                const [pos, vel] = root.spring(t);
                shapeCanvas.morphProgress = Math.min(1, pos);
                shapeCanvas.rotation = root.rotationStart + pos * (root.rotationTarget - root.rotationStart);
                shapeCanvas.scale = 1 + vel * 0.14 / root.springMaxVelocity;
            }
        }
    }

    Timer {
        id: animTimer

        interval: 1000
        running: root.status
        repeat: root.status
        triggeredOnStart: true
        onTriggered: {
            const nextIndex = (root.shapeIndex + 1) % root.shapeGetters.length;

            shapeCanvas.fromShape = root.shapeGetters[root.shapeIndex];
            shapeCanvas.toShape = root.shapeGetters[nextIndex];
            shapeCanvas.morphProgress = 0;

            root.shapeIndex = nextIndex;
            root.rotationStart = shapeCanvas.rotation;
            root.rotationTarget = shapeCanvas.rotation + root.rotationStep;
            root.springSettled = false;
            timer.restart();
        }
    }

    MaterialShape {
        id: shapeCanvas

        anchors.centerIn: parent
        implicitWidth: parent.width
        implicitHeight: parent.height
        color: Colours.m3Colors.m3Primary

        fromShape: root.shapeGetters[root.shapeIndex]
        toShape: root.shapeGetters[root.shapeIndex]
        morphProgress: 1

        scale: root.status ? 1 : 0

        Behavior on scale {
            SpringAnimation {
                spring: 5
                damping: 0.3
                epsilon: 0.1
            }
        }
    }
}
