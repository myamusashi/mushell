pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property list<string> maskChars: ["m", "y", "a", "m", "u", "s", "a", "s", "h", "i"]

    property string inputBuffer: ""
    property string maskedBuffer: ""
    property bool showErrorMessage: false
    property bool isAllSelected: false
    property int fakeTypingTimer: 0
    property var lastKeystrokeTime: 0

    Connections {
        target: root.lock

        function onUnlock(): void {
            unlockSequence.start();
        }
    }

    Connections {
        target: root.pam
        enabled: root.pam !== null

        function onShowFailureChanged() {
            if (root.pam.showFailure) {
                root.showErrorMessage = true;
                errorShakeAnimation.start();
            }
        }
    }

    StyledRect {
        id: surface

        anchors.fill: parent
        focus: true

        color: Colours.m3Colors.m3SurfaceContainerLowest

        Keys.onPressed: kevent => {
            if (root.showErrorMessage && kevent.text)
                root.showErrorMessage = false;

            if (kevent.key === Qt.Key_Enter || kevent.key === Qt.Key_Return) {
                root.pam.currentText = root.inputBuffer;
                root.pam.tryUnlock();
                root.inputBuffer = "";
                root.maskedBuffer = "";
                passwordBuffer.color = Colours.m3Colors.m3OnSurfaceVariant;
                root.lastKeystrokeTime = 0;
                return;
            }

            if (kevent.key === Qt.Key_A && (kevent.modifiers & Qt.ControlModifier)) {
                passwordBuffer.color = Colours.m3Colors.m3Blue;
                root.isAllSelected = true;
                kevent.accepted = true;
                return;
            }

            if (kevent.key === Qt.Key_Backspace) {
                if (kevent.modifiers & Qt.ControlModifier) {
                    passwordBuffer.color = Colours.m3Colors.m3OnBackground;
                    root.inputBuffer = "";
                    root.maskedBuffer = "";
                    root.isAllSelected = false;
                    return;
                }

                if (root.isAllSelected) {
                    root.inputBuffer = "";
                    root.maskedBuffer = "";
                    passwordBuffer.color = Colours.m3Colors.m3OnSurfaceVariant;
                    root.isAllSelected = false;
                    return;
                }

                root.inputBuffer = root.inputBuffer.slice(0, -1);

                const randomRemove = Math.min(Math.floor(Math.random() * 3) + 1, root.maskedBuffer.length);
                root.maskedBuffer = root.maskedBuffer.slice(0, -randomRemove);

                if (root.maskedBuffer === "")
                    passwordBuffer.color = Colours.m3Colors.m3OnSurfaceVariant;

                return;
            }

            if (kevent.text) {
                if (root.isAllSelected) {
                    root.inputBuffer = "";
                    root.maskedBuffer = "";
                    root.isAllSelected = false;
                }

                if (passwordBuffer.color === Colours.m3Colors.m3Blue || passwordBuffer.color === Colours.m3Colors.m3OnBackground)
                    passwordBuffer.color = root.maskedBuffer ? Colours.m3Colors.m3OnSurface : Colours.m3Colors.m3OnSurfaceVariant;

                root.inputBuffer += kevent.text;

                const randomLength = Math.floor(Math.random() * 3) + 1;
                for (var i = 0; i < randomLength; i++)
                    root.maskedBuffer += root.maskChars[Math.floor(Math.random() * root.maskChars.length)];

                const currentTime = Date.now();
                if (root.lastKeystrokeTime > 0) {
                    const timeDelta = currentTime - root.lastKeystrokeTime;
                    if (timeDelta < 50) {
                        fakeDelayTimer.interval = Math.random() * 30 + 10;
                        fakeDelayTimer.restart();
                    }
                }
                root.lastKeystrokeTime = currentTime;

                typingAnimation.restart();
            }
        }

        Timer {
            id: fakeDelayTimer

            interval: 20
            repeat: false
            onTriggered: {
                passwordBuffer.opacity = 0.99;
                passwordBuffer.opacity = 1.0;
            }
        }

        Timer {
            id: fakeTypingTimer

            interval: Math.random() * 3000 + 2000
            repeat: true
            running: root.lock.locked && root.maskedBuffer.length > 0

            onTriggered: {
                // Randomly add or remove fake characters when idle
                if (Math.random() > 0.5 && root.maskedBuffer.length < 50)
                    root.maskedBuffer += root.maskChars[Math.floor(Math.random() * root.maskChars.length)];
                else if (root.maskedBuffer.length > root.inputBuffer.length * 3)
                    root.maskedBuffer = root.maskedBuffer.slice(0, -1);
                interval = Math.random() * 3000 + 2000;
            }
        }

        Wallpaper {
            id: wallpaper
        }

        ColumnLayout {
            id: clockContainer

            anchors.centerIn: parent
            anchors.verticalCenterOffset: -80
            spacing: Appearance.spacing.normal
            opacity: 0
            scale: 0.8
            z: 1

            Clock {}
        }

        StyledLabel {
            id: errorLabel

            anchors.centerIn: parent
            anchors.verticalCenterOffset: -60
            text: "WRONG"
            color: Colours.m3Colors.m3Error
            font.pointSize: Appearance.fonts.size.large * 5
            opacity: root.showErrorMessage ? 1 : 0
            visible: opacity > 0
            z: 2

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        StyledLabel {
            id: passwordBuffer

            anchors.centerIn: parent
            text: root.showErrorMessage ? "" : root.maskedBuffer
            color: root.maskedBuffer ? (root.pam.showFailure ? Colours.m3Colors.m3OnErrorContainer : Colours.m3Colors.m3OnSurface) : Colours.m3Colors.m3OnSurfaceVariant
            font.pointSize: Appearance.fonts.size.extraLarge * 5
            font.family: Appearance.fonts.family.mono
            z: 0

            property real randomXOffset: 0
            property real randomYOffset: 0

            transform: Translate {
                x: passwordBuffer.randomXOffset
                y: passwordBuffer.randomYOffset
            }

            Timer {
                interval: 100
                repeat: true
                running: root.lock.locked && root.maskedBuffer.length > 0
                onTriggered: {
                    passwordBuffer.randomXOffset = (Math.random() - 0.5) * 4;
                    passwordBuffer.randomYOffset = (Math.random() - 0.5) * 4;
                }
            }

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            Behavior on font.pointSize {
                NAnim {
                    duration: 100
                }
            }

            Timer {
                interval: 200
                repeat: true
                running: root.lock.locked && root.maskedBuffer.length > 0
                onTriggered: {
                    const baseFontSize = Appearance.fonts.size.extraLarge * 5;
                    passwordBuffer.font.pointSize = baseFontSize * (0.95 + Math.random() * 0.1);
                }
            }
        }

        SessionButton {
            id: sessionContainer

            spacing: Appearance.spacing.normal
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Appearance.spacing.large
        }
    }

    SequentialAnimation {
        id: unlockSequence

        PropertyAction {
            targets: GlobalStates
            properties: "hideOuterBorder"
            value: false
        }

        PauseAnimation {
            duration: Appearance.animations.durations.extraLarge
        }

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
                property: "anchors.verticalCenterOffset"
                from: -80
                to: -100
                duration: Appearance.animations.durations.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
        }

        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }

        PauseAnimation {
            duration: Appearance.animations.durations.extraLarge
        }
    }

    SequentialAnimation {
        id: entrySequence

        running: true

        PauseAnimation {
            duration: Appearance.animations.durations.extraLarge
        }

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
                from: 0.9
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
            PropertyAnimation {
                target: sessionContainer
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
        }
    }

    SequentialAnimation {
        id: errorShakeAnimation

        PropertyAnimation {
            target: errorLabel
            property: "anchors.horizontalCenterOffset"
            from: 0
            to: -8
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        PropertyAnimation {
            target: errorLabel
            property: "anchors.horizontalCenterOffset"
            from: -8
            to: 8
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.standardAccel
        }
        PropertyAnimation {
            target: errorLabel
            property: "anchors.horizontalCenterOffset"
            from: 8
            to: -4
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.standardAccel
        }
        PropertyAnimation {
            target: errorLabel
            property: "anchors.horizontalCenterOffset"
            from: -4
            to: 0
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
    }

    SequentialAnimation {
        id: typingAnimation

        ParallelAnimation {
            NAnim {
                target: passwordBuffer
                property: "scale"
                from: 0.9
                to: 1.0
                duration: Appearance.animations.durations.small
                easing.type: Easing.Linear
                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            }
            NAnim {
                target: passwordBuffer
                property: "opacity"
                from: 0.5
                to: 1.0
                duration: Appearance.animations.durations.small
                easing.type: Easing.Linear
                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            }
        }
    }
}
