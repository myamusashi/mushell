import QtQuick

import qs.Core.Utils
import qs.Services

import "../Base"

Item {
    id: root

    anchors.fill: parent

    property alias source: borderEffect.source
    property alias progress: borderEffect.progress
    property alias radius: borderEffect.radius
    property alias borderWidth: borderEffect.borderWidth
    property alias borderColor: borderEffect.borderColor
    property alias animationDuration: progressAnimation.duration
    property alias animation: progressAnimation

    ShaderEffect {
        id: borderEffect

        anchors.fill: parent

        property var source: ({})
        property real progress: 1.0
        property real radius: source.radius
        property real borderWidth: 2.0
        property vector2d resolution: Qt.vector2d(source.width, source.height)
        property color borderColor: Colours.m3Colors.m3Primary

        z: 999
        vertexShader: Paths.projectRoot + "/Assets/shaders/borderProgress.vert.qsb"
        fragmentShader: Paths.projectRoot + "/Assets/shaders/borderProgress.frag.qsb"
    }

    NAnim {
        id: progressAnimation

        target: borderEffect
        property: "progress"
        from: 1.0
        to: 0.0
        duration: 500
        onFinished: borderEffect.destroy()
    }
}
