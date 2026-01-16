import QtQuick
import M3Shapes

import qs.Services

Item {
    id: root

    anchors.centerIn: parent

    property bool status: false
    property double radius: 50
    property double padding: 50
    property double shapePadding: 12
    property var shapeGetters: [MaterialShape.Oval, MaterialShape.SoftBurst, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided]
    property int shapeIndex: 0
    property int rotationSpeed: 5000

    implicitWidth: 30
    implicitHeight: 30
    visible: status

    Timer {
        id: morphTimer

        interval: 1500
        running: root.status
        repeat: root.status
        onTriggered: {
            root.rotationSpeed = 2000;
            rotationAnim.restart();

            morphDelay.start();
        }
    }

    Timer {
        id: morphDelay

        interval: 100
        onTriggered: {
            root.shapeIndex = (root.shapeIndex + 1) % root.shapeGetters.length;

            root.rotationSpeed = 5000;
            rotationAnim.restart();
        }
    }

    MaterialShape {
        id: shapeCanvas

        anchors.centerIn: parent
        implicitWidth: parent.width
        implicitHeight: parent.height
        color: Colours.m3Colors.m3OnPrimary
        shape: root.shapeGetters[root.shapeIndex]

        RotationAnimator {
            id: rotationAnim

            target: shapeCanvas
            loops: Animation.Infinite
            from: shapeCanvas.rotation
            to: shapeCanvas.rotation + 360
            duration: root.rotationSpeed
            easing.type: Easing.OutQuart
            running: true
        }
    }
}
