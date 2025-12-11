import QtQuick

import qs.Configs

ColorAnimation {
    duration: Appearance.animations.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.animations.curves.standard
}
