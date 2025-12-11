import QtQuick

import qs.Configs
import qs.Helpers
import qs.Services

import "../Submodules/rounded-polygon-qmljs/material-shapes.js" as MaterialShapes
Item {
    id: root

	property bool status: false
    property double radius: 50
    property double padding: 50
    property double shapePadding: 12
    anchors.centerIn: parent
    implicitWidth: 30
	implicitHeight: 30
	visible: status

    property var shapeGetters: [MaterialShapes.getOval, MaterialShapes.getSoftBurst, MaterialShapes.getPentagon, MaterialShapes.getPill, MaterialShapes.getSunny, MaterialShapes.getCookie4Sided]
    property int shapeIndex: 0
    property int rotationSpeed: 5000

    // Automatic morphing
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

    ShapeCanvas {
		id: shapeCanvas

        anchors.centerIn: parent
        implicitWidth: parent.width
        implicitHeight: parent.height
        color: Colours.m3Colors.m3OnPrimary
        roundedPolygon: root.shapeGetters[root.shapeIndex]()
        onProgressChanged: requestPaint()

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
