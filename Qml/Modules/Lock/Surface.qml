pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    property bool isClosing: false
    property bool showErrorMessage: false

    property string inputBuffer: ""
    property string maskedBuffer: ""
    property bool isAllSelected: false
    readonly property list<string> maskChars: ["║", "║▌█", "║▌", "▌│", "█║", "𝄂▌║", "▌│", "█║", "𝄂▌║"]

    color: "transparent"
    property bool zoomedIn: false

    property color cFrom
    property color cTo
    property bool cActive: false
    property real cBlend: 1.0

    onCBlendChanged: {
        if (!cActive)
            return;
        if (cBlend >= 1) {
            bottomItem.lockIcon.color = cTo;
            cActive = false;
        } else if (cBlend > 0) {
            bottomItem.lockIcon.color = Colours.blendColors(cFrom, cTo, cBlend);
        }
    }

    NAnim {
        id: cAnim
        target: root
        property: "cBlend"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.small
        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
    }

    onInputBufferChanged: {
        var diff = root.inputBuffer.length - root.maskedBuffer.length;
        var grew = diff > 0;
        while (diff > 0) {
            root.maskedBuffer += root.maskChars[Math.floor(Math.random() * root.maskChars.length)];
            diff--;
        }
        while (diff < 0) {
            root.maskedBuffer = root.maskedBuffer.substring(0, root.maskedBuffer.length - 1);
            diff++;
        }
        root.isAllSelected = false;
        if (grew && root.inputBuffer.length > 0 && !root.zoomedIn) {
            root.zoomedIn = true;
            zoomInAnimation.start();
        }
    }

    Connections {
        target: root.lock

        function onUnlock(): void {
            root.isClosing = true;
            unlockSequence.start();
        }
    }

    Connections {
        target: root.pam
        enabled: root.pam !== null

        function onShowFailureChanged() {
            if (root.pam.showFailure) {
                root.showErrorMessage = true;
                root.inputBuffer = "";
                root.maskedBuffer = "";
                root.zoomedIn = false;
                zoomOutAnimation.start();
                errorShakeAnimation.start();
            } else {
                root.showErrorMessage = false;
            }
        }
    }

    Item {
        id: wallpaper

        anchors.fill: parent
        opacity: 0
        transformOrigin: Item.Center
        property real blurRadius: 0
        layer.enabled: wallpaper.blurRadius > 0
        layer.effect: FastBlur {
            source: wallpaper
            radius: wallpaper.blurRadius
            transparentBorder: false
        }

        Wallpaper {
            anchors.fill: parent
            visible: true
        }

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
            }
        }
    }

    StyledRect {
        id: rectSurface

        anchors.fill: parent

        radius: 0
        color: "transparent"

        Component.onCompleted: {
            lockSequence.start();
        }

        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.inputBuffer.length > 0) {
                    if (root.zoomedIn) {
                        zoomOutAnimation.start();
                    }
                    root.pam.currentText = root.inputBuffer;
                    root.pam.tryUnlock();
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Backspace) {
                if (root.isAllSelected) {
                    root.inputBuffer = "";
                    root.isAllSelected = false;
                } else if (event.modifiers & Qt.ControlModifier) {
                    const idx = root.inputBuffer.lastIndexOf(' ');
                    root.inputBuffer = root.inputBuffer.substring(0, idx > -1 ? idx : 0);
                } else if (root.inputBuffer.length > 0) {
                    root.inputBuffer = root.inputBuffer.substring(0, root.inputBuffer.length - 1);
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                root.isAllSelected = true;
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Escape) {
                if (root.zoomedIn) {
                    zoomOutAnimation.start();
                }
                if (root.isAllSelected) {
                    root.isAllSelected = false;
                } else {
                    root.inputBuffer = "";
                }
                root.zoomedIn = false;
                event.accepted = true;
                return;
            }

            const text = event.text;
            if (text.length === 1 && text.charCodeAt(0) >= 32) {
                if (root.isAllSelected) {
                    root.inputBuffer = "";
                    root.isAllSelected = false;
                }
                root.inputBuffer += text;
                event.accepted = true;
            }
        }

        StyledText {
            id: passwordDisplay

            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }

            text: root.maskedBuffer.length > 0 ? root.maskedBuffer : (root.showErrorMessage ? "" : "·")
            color: root.showErrorMessage ? Colours.m3Colors.m3Error : root.isAllSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.extraLarge * 10
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            z: 3
            opacity: root.inputBuffer.length > 0 || root.showErrorMessage ? 1.0 : 0.3

            transform: Translate {
                id: passwordShake
                x: 0
            }

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }
    }

    Image {
        id: fgLayer

        readonly property bool currentWallpaperIsVideo: /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(Paths.currentWallpaper)

        anchors.fill: parent
        source: !currentWallpaperIsVideo && Configs.wallpaper.depthWallpaperEnabled && Configs.wallpaper.depthFgPath !== "" ? "file://" + Configs.wallpaper.depthFgPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: 0
        scale: 1.0
        visible: !currentWallpaperIsVideo && Configs.wallpaper.depthWallpaperEnabled && Configs.wallpaper.depthFgPath !== "" && !DepthWallpaperController.generating && GlobalStates.previewWallpaper === ""
        z: 2
    }

    BottomItem {
        id: bottomItem
        z: 3

        isLockscreenOpen: GlobalStates.isLockscreenOpen
        pam: root.pam
        inputBuffer: root.inputBuffer
        showErrorMessage: root.showErrorMessage
    }

    SequentialAnimation {
        id: lockSequence

        ParallelAnimation {
            NAnim {
                target: bottomItem
                property: "implicitHeight"
                to: 80
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem.contentLayout
                property: "opacity"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "opacity"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: fgLayer
                property: "opacity"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: passwordDisplay
                property: "opacity"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ScriptAction {
            script: {
                GlobalStates.isLockscreenOpen = true;
            }
        }
    }

    SequentialAnimation {
        id: unlockSequence

        NAnim {
            target: bottomItem.lockIcon
            property: "rotation"
            to: 18
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: bottomItem.lockIcon
            property: "rotation"
            to: -18
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: bottomItem.lockIcon
            property: "rotation"
            to: 12
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: bottomItem.lockIcon
            property: "rotation"
            to: -12
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: bottomItem.lockIcon
            property: "rotation"
            to: 6
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: bottomItem.lockIcon
            property: "rotation"
            to: -6
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: bottomItem.lockIcon
            property: "rotation"
            to: 0
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        ScriptAction {
            script: {
                cAnim.stop();
                cFrom = bottomItem.lockIcon.color;
                cTo = Colours.m3Colors.m3Green;
                cActive = true;
                cBlend = 0.0;
                cAnim.start();
                bottomItem.iconName = "lock_open_right";
            }
        }

        PauseAnimation {
            duration: Appearance.animations.durations.emphasized
        }

        ParallelAnimation {
            NAnim {
                target: bottomItem
                property: "implicitHeight"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem.contentLayout
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "blurRadius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: fgLayer
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: passwordDisplay
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ScriptAction {
            script: {
                root.lock.locked = false;
                GlobalStates.isLockscreenOpen = false;
                root.pam.isUnlock = false;
                root.pam.currentText = "";
                root.zoomedIn = false;
            }
        }
    }

    SequentialAnimation {
        id: errorShakeAnimation

        NAnim {
            target: passwordShake
            property: "x"
            to: 12
            duration: 50
        }
        NAnim {
            target: passwordShake
            property: "x"
            to: -12
            duration: 50
        }
        NAnim {
            target: passwordShake
            property: "x"
            to: 8
            duration: 50
        }
        NAnim {
            target: passwordShake
            property: "x"
            to: -8
            duration: 50
        }
        NAnim {
            target: passwordShake
            property: "x"
            to: 4
            duration: 50
        }
        NAnim {
            target: passwordShake
            property: "x"
            to: 0
            duration: 50
        }
    }

    Timer {
        id: jitterTimer
        interval: 2500
        repeat: true
        running: root.inputBuffer.length > 0
        onTriggered: {
            const idx = Math.floor(Math.random() * root.inputBuffer.length);
            const arr = root.maskedBuffer.split('');
            arr[idx] = root.maskChars[Math.floor(Math.random() * root.maskChars.length)];
            root.maskedBuffer = arr.join('');
        }
    }

    SequentialAnimation {
        id: zoomInAnimation

        ParallelAnimation {
            NAnim {
                target: wallpaper
                property: "scale"
                to: 1.12
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "blurRadius"
                to: 30
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: fgLayer
                property: "scale"
                to: 1.12
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "implicitHeight"
                to: 0
                duration: Appearance.animations.durations.emphasizedAccel
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    CapsLockPopup {
        anchors.centerIn: parent
        z: 999
    }

    SequentialAnimation {
        id: zoomOutAnimation

        ParallelAnimation {
            NAnim {
                target: wallpaper
                property: "scale"
                to: 1.0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "blurRadius"
                to: 0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: fgLayer
                property: "scale"
                to: 1.0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "opacity"
                to: 1
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "implicitHeight"
                to: 80
                duration: Appearance.animations.durations.emphasizedAccel
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }
}
