pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Slider {
    id: slider

    readonly property bool isWavy: Configs.mediaPlayer.sliderType === "Wavy"
    readonly property bool isWaveForm: Configs.mediaPlayer.sliderType === "WaveForm"
    readonly property int stepCount: slider.pressed ? Math.ceil(width / 2.0) : Math.ceil(width / 0.6)

    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3SecondaryContainer
    property int separatorWidth: 8
    property bool enableWave: true
    property real waveTransition: 1.0

    // Wavy
    property int waveAmplitude: 2
    property real waveFrequency: 9.0
    property real waveAnimPhase: 0.0

    // WaveForm
    property real waveFreqBeach: 3.8
    property real wavePow: 0.90
    property real waveFloor: 0.44
    property real waveRamp: 0.1
    property real waveRampIn: 0.1
    property real waveMaxAmpRatio: 0.50
    property real wavePhaseBeach: 0.0
    property real effectiveWaveRamp: slider.waveRamp

    Behavior on effectiveWaveRamp {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }

    Behavior on waveTransition {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    snapMode: Slider.NoSnap
    hoverEnabled: true
    antialiasing: true
    smooth: true
    onEnableWaveChanged: waveTransition = enableWave ? 1.0 : 0.0

    // FrameAnimation adds a fixed delta every frame regardless of the current
    // wavePhase value, so pause/resume has zero effect on perceived speed.
    // fmod keeps the value in [0, 2π] without ever accumulating float error
    FrameAnimation {
        id: wavyPhaseDriver

        running: slider.enableWave && slider.isWavy
        // 2000ms full cycle → 2π / 2.0 radians per second
        onTriggered: slider.waveAnimPhase = (slider.waveAnimPhase + Math.PI * 2 * frameTime / 2.0) % (Math.PI * 2)
    }

    FrameAnimation {
        id: waveFormPhaseDriver

        running: slider.enableWave && slider.isWaveForm
        // 3000ms full cycle → 2π / 3.0 radians per second
        onTriggered: slider.wavePhaseBeach = (slider.wavePhaseBeach + Math.PI * 2 * frameTime / 3.0) % (Math.PI * 2)
    }

    background: Item {
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: slider.availableWidth
        implicitHeight: 40

        Loader {
            anchors.fill: parent
            active: slider.isWavy
            sourceComponent: wavyShaderComponent
        }

        Component {
            id: wavyShaderComponent

            ShaderEffect {
                blending: true

                property color activeColor: slider.activeColor
                property color inactiveColor: slider.inactiveColor
                property real effectWidth: width
                property real centerY: height * 0.5
                property real activeEnd: Math.max(0, width * slider.visualPosition - slider.separatorWidth * 0.5)
                property real inactiveStart: Math.min(width, width * slider.visualPosition + slider.separatorWidth * 0.5)
                property real waveFrequency: slider.waveFrequency
                property real waveAmplitude: slider.waveAmplitude * slider.waveTransition
                property real wavePhase: slider.waveAnimPhase
                property real strokeHalfWidth: 0.75

                vertexShader: Paths.projectRoot + "/Assets/shaders/wavy.vert.qsb"
                fragmentShader: Paths.projectRoot + "/Assets/shaders/wavy.frag.qsb"
            }
        }

        Loader {
            anchors.fill: parent
            active: slider.isWaveForm
            sourceComponent: waveFormShaderComponent
        }
    }

    Component {
        id: waveFormShaderComponent

        ShaderEffect {
            blending: true

            property color activeColor: slider.activeColor
            property color inactiveColor: slider.inactiveColor
            property real effectWidth: width
            property real baselineY: height * 0.5
            property real waveAmplitude: height * slider.waveMaxAmpRatio
            property real activeEnd: Math.max(0, width * slider.visualPosition - slider.separatorWidth * 0.5)
            property real inactiveStart: Math.min(width, width * slider.visualPosition + slider.separatorWidth * 0.5)
            property real playPosition: slider.visualPosition
            property real wavePhase: slider.wavePhaseBeach
            property real waveFrequency: slider.waveFreqBeach
            property real shapeExponent: slider.wavePow
            property real amplitudeFloor: slider.waveFloor
            property real playheadRamp: slider.effectiveWaveRamp
            property real leadingRamp: slider.waveRampIn
            property real transitionAmount: slider.waveTransition
            property real strokeHalfWidth: 0.9

            vertexShader: Paths.projectRoot + "/Assets/shaders/waveForm.vert.qsb"
            fragmentShader: Paths.projectRoot + "/Assets/shaders/waveForm.frag.qsb"
        }
    }

    handle: Item {
        id: handleRoot

        x: slider.leftPadding + slider.visualPosition * slider.availableWidth - implicitWidth / 2
        y: slider.topPadding + slider.availableHeight / 2 - implicitHeight / 2
        implicitWidth: 22
        implicitHeight: 40

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 20
            radius: 3
            color: slider.activeColor
            visible: slider.isWavy
            scale: slider.pressed ? 1.3 : 1
            Behavior on scale {
                NAnim {}
            }
        }

        Rectangle {
            anchors.centerIn: parent
            visible: slider.isWaveForm
            width: 6
            height: 20
            radius: 3
            color: slider.activeColor
        }
    }
}
