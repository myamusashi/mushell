import QtQuick

import qs.Configs

NumberAnimation {
    duration: Appearance.animations.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.animations.curves.standard
}
