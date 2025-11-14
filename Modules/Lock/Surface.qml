pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Wayland

import qs.Data
import qs.Components

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    Connections {
        target: root.lock

        function onUnlock(): void {
            unlockSequence.start()
        }
    }

    StyledRect {
        id: surface

        anchors.fill: parent

        color: Themes.colors.surface_container_lowest

        Wallpaper {
            id: wallpaper

            layer.enabled: true
            layer.effect: MultiEffect {
                id: wallBlur

                autoPaddingEnabled: false
                blurEnabled: true

                NumbAnim on blur {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.type: Easing.Linear
                    from: 0
                    to: 0.69
                }

                NumbAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial * 1.5
                    easing.type: Easing.Linear
                    property: "blur"
                    running: root.lock.locked
                    target: wallBlur
                    to: 0
                }
            }
        }

        ColumnLayout {
            id: clockContainer

            anchors {
                centerIn: parent
                verticalCenterOffset: -80
            }
            spacing: Appearance.spacing.normal
            opacity: 0
            scale: 0.8

            Clock {}
        }

        ColumnLayout {
            id: inputContainer

            spacing: Appearance.spacing.larger
            opacity: 0
            scale: 0.95

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Appearance.spacing.large * 4
            }

            InputField {
                pam: root.pam
            }
        }

        ColumnLayout {
            id: sessionContainer

            spacing: Appearance.spacing.normal
            opacity: 0
            scale: 0.8

            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: Appearance.spacing.large
            }

            SessionButton {}
        }
    }

    SequentialAnimation {
        id: unlockSequence

        ParallelAnimation {
            PropertyAnimation {
                target: clockContainer
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.animations.durations.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
            PropertyAnimation {
                target: clockContainer
                property: "scale"
                from: 1
                to: 0.9
                duration: Appearance.animations.durations.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
            PropertyAnimation {
                target: clockContainer
                property: "y"
                from: clockContainer.y
                to: clockContainer.y - 20
                duration: Appearance.animations.durations.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: inputContainer
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
            PropertyAnimation {
                target: inputContainer
                property: "scale"
                from: 1
                to: 0.85
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }

            PropertyAnimation {
                target: sessionContainer
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
            PropertyAnimation {
                target: sessionContainer
                property: "scale"
                from: 1
                to: 0.85
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
        }

        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    SequentialAnimation {
        id: entrySequence
        running: true

        ParallelAnimation {
            PropertyAnimation {
                target: clockContainer
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
            PropertyAnimation {
                target: clockContainer
                property: "scale"
                from: 0.8
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
            PropertyAnimation {
                target: clockContainer
                property: "y"
                from: clockContainer.y + 30
                to: clockContainer.y
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
        }

        ParallelAnimation {
            PropertyAnimation {
                target: inputContainer
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.standard
            }
            PropertyAnimation {
                target: inputContainer
                property: "scale"
                from: 0.9
                to: 1
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.standard
            }
            PropertyAnimation {
                target: inputContainer
                property: "y"
                from: inputContainer.y + 20
                to: inputContainer.y
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.standard
            }

            PropertyAnimation {
                target: sessionContainer
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.standard
            }
            PropertyAnimation {
                target: sessionContainer
                property: "scale"
                from: 0.9
                to: 1
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.standard
            }
            PropertyAnimation {
                target: sessionContainer
                property: "y"
                from: sessionContainer.y + 20
                to: sessionContainer.y
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.standard
            }
        }
    }

    Connections {
        target: root.pam
        enabled: root.pam !== null

        function onShowFailureChanged() {
            if (root.pam.showFailure)
                errorShakeAnimation.start()
        }
    }

    SequentialAnimation {
        id: errorShakeAnimation

        PropertyAnimation {
            target: inputContainer
            property: "anchors.horizontalCenterOffset"
            from: 0
            to: -8
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        PropertyAnimation {
            target: inputContainer
            property: "anchors.horizontalCenterOffset"
            from: -8
            to: 8
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.standardAccel
        }
        PropertyAnimation {
            target: inputContainer
            property: "anchors.horizontalCenterOffset"
            from: 8
            to: -4
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.standardAccel
        }
        PropertyAnimation {
            target: inputContainer
            property: "anchors.horizontalCenterOffset"
            from: -4
            to: 0
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
    }
}
