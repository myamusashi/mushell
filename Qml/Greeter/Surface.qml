pragma ComponentBehavior: Bound

import QtQuick

import Quickshell.Wayland

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Auth auth

    signal successSequenceFinished
    signal logoutRequested

    readonly property var _transitionNames: ["fade", "wipeDown", "circleExpand", "dissolve", "splitHorizontal", "slideUp", "pixelate", "diagonalWipe", "boxExpand", "roll", "hexTile"]
    readonly property var _transitionConfigNames: ["fade", "wipedown", "circle", "dissolve", "splith", "slideup", "pixelate", "diagonal", "box", "roll", "hextile"]

    function successTransitionShader() {
        if (Configs.wallpaper.transitionLowPerfMode || Configs.wallpaper.transition === "none")
            return "fade";
        const configured = (Configs.wallpaper.transition || "random").toLowerCase();
        if (configured === "random")
            return _transitionNames[Math.floor(Math.random() * _transitionNames.length)];
        const index = _transitionConfigNames.indexOf(configured);
        return index >= 0 ? _transitionNames[index] : "fade";
    }

    function updateSuccessResolution() {
        successFx.resolution = Qt.vector2d(successFx.width, successFx.height);
        successFx.invResolution = Qt.vector2d(1.0 / Math.max(1, successFx.width), 1.0 / Math.max(1, successFx.height));
    }

    function playSuccessSequence() {
        successSequence.start();
    }

    color: "transparent"

    WallpaperView {
        id: wallpaper

        anchors.fill: parent
        wallpaperOpacity: 1
    }

    Rectangle {
        id: successTarget

        anchors.fill: parent
        color: Colours.m3Colors.m3Primary
        visible: false
        layer.enabled: true
    }

    ShaderEffect {
        id: successFx

        anchors.fill: parent
        visible: false
        blending: false
        layer.enabled: false

        property Item source1: wallpaper.effectSource
        property Item source2: successTarget

        property real progress: 0.0
        property real smoothAmount: 0.05
        property real aspect: root.height > 0.0 ? root.height / root.width : 1.0
        property vector2d resolution: Qt.vector2d(720, 720)
        property vector2d invResolution: Qt.vector2d(1.0 / 720, 1.0 / 720.0)

        vertexShader: Paths.projectRoot + "/Assets/shaders/ImageTransition.vert.qsb"
        fragmentShader: Paths.projectRoot + "/Assets/shaders/transitions/" + root.successTransitionShader() + ".frag.qsb"

        onWidthChanged: root.updateSuccessResolution()
        onHeightChanged: root.updateSuccessResolution()
        Component.onCompleted: root.updateSuccessResolution()
    }

    Item {
        id: uiContainer

        anchors.fill: parent
        opacity: 0

        GreeterUi {
            id: ui

            anchors.fill: parent
            auth: root.auth
            playEntrance: false

            onLogoutRequested: root.logoutRequested()
        }
    }

    Component.onCompleted: {
        lockInSequence.start();
    }

    SequentialAnimation {
        id: lockInSequence

        NAnim {
            target: uiContainer
            property: "opacity"
            to: 1
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Connections {
        target: root.auth

        function onAuthenticated() {
            root.playSuccessSequence();
        }
    }

    SequentialAnimation {
        id: successSequence

        PauseAnimation {
            duration: 120
        }

        ScriptAction {
            script: {
                successFx.visible = true;
                successTarget.visible = true;
            }
        }

        ParallelAnimation {
            NAnim {
                target: uiContainer
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: uiContainer
                property: "scale"
                to: 1.04
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NumberAnimation {
                target: successFx
                property: "progress"
                from: 0
                to: 1
                duration: Configs.wallpaper.transitionDuration
                easing.type: Easing.Linear
            }
        }

        onStopped: unlockSequence.start()
    }

    SequentialAnimation {
        id: unlockSequence

        ParallelAnimation {
            NAnim {
                target: successFx
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: successTarget
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        onStopped: root.successSequenceFinished()
    }
}
