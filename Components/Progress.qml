import QtQuick
import QtQuick.Layouts

import qs.Configs

Rectangle {
    id: root

    property bool condition: false

    Layout.fillWidth: true
    height: 2
    visible: condition
    color: "transparent"

    Rectangle {
        id: loadingBar

        width: parent.width * 0.3
        height: parent.height
        radius: height / 2
        color: Themes.m3Colors.primary

        SequentialAnimation on x {
            loops: Animation.Infinite
            running: root.condition

            XAnimator {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.standard
                easing.type: Easing.BezierSpline
                easing.amplitude: 1.0
                easing.period: 0.5
                from: 0
                to: root.width - loadingBar.width
            }

            XAnimator {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.standard
                easing.type: Easing.BezierSpline
                easing.amplitude: 1.0
                easing.period: 0.5
                from: root.width - loadingBar.width
                to: 0
            }
        }
    }
}
