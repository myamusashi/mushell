import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "Calendar"
import "Clipboard"
import "Launcher"
import "QuickSettings"
import "Notifications"
import "Session"
import "WallpaperSelector"
import "Weather"
import "OSD"
import "Bar"
import "Volume"
import "ScreenRecorder"
import "DynamicIsland"

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: window

        anchors {
            left: true
            top: true
            right: true
            bottom: true
        }

        required property ShellScreen modelData
        readonly property bool needFocusKeyboard: {
            if (GlobalStates.isLauncherOpen)
                return true;
            if (GlobalStates.isSessionOpen && !session.showConfirmDialog)
                return true;
            if (GlobalStates.isWallpaperSwitcherOpen)
                return true;
            if (GlobalStates.isScreenCapturePanelOpen)
                return true;
            if (GlobalStates.isClipboardOpen)
                return true;
            return false;
        }

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "shell:drawers"
        WlrLayershell.keyboardFocus: needFocusKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        // HyprlandWindow.visibleMask: Region {
        //     item: window.contentItem.children
        // }
        // BackgroundEffect.blurRegion: Region {
        //     item: window.contentItem.children
        // }

        mask: Region {
            regions: childRegions.instances
            item: cornersArea
            intersection: Intersection.Subtract
        }

        Variants {
            id: childRegions

            model: window.contentItem.children
            delegate: Region {
                required property Item modelData
                item: modelData
                intersection: Intersection.Xor
            }
        }

        Scope {
            Exclusion {
                id: exclusiveLeft

                anchors.left: true

                property alias zone: exclusiveLeft.exclusiveZone

                screen: window.modelData
                name: "left"
                exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
            }
            Exclusion {
                id: exclusiveTop

                anchors.top: true

                property alias zone: exclusiveTop.exclusiveZone

                screen: window.modelData
                name: "top"
                exclusiveZone: {
                    if (GlobalStates.isBarOpen) {
                        if (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name)
                            return Configs.generals.outerBorderSize + Configs.bar.barHeight;
                        else {
                            if (Configs.generals.enableOuterBorder)
                                return Configs.generals.outerBorderSize;
                            else
                                return 0;
                        }
                    } else
                        return Configs.generals.outerBorderSize;
                }
            }
            Exclusion {
                id: exclusiveRight

                anchors.right: true

                property alias zone: exclusiveRight.exclusiveZone

                screen: window.modelData
                name: "right"
                exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
            }
            Exclusion {
                id: exclusiveBottom

                anchors.bottom: true

                property alias zone: exclusiveBottom.exclusiveZone

                screen: window.modelData
                name: "bottom"
                exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
            }
        }

        Rectangle {
            id: rect

            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: leftBar

                anchors.left: parent.left
                implicitWidth: exclusiveLeft.zone
                implicitHeight: QsWindow.window?.height ?? 0
                color: GlobalStates.drawerColors

                ElevatedCharging {}
            }

            Rectangle {
                id: topBar

                anchors.top: parent.top
                implicitWidth: QsWindow.window?.width ?? 0
                implicitHeight: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) ? exclusiveTop.zone : 0
                color: GlobalStates.drawerColors

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                ElevatedCharging {}
            }

            Rectangle {
                id: rightBar

                anchors.right: parent.right
                implicitWidth: exclusiveRight.zone
                implicitHeight: QsWindow.window?.height ?? 0
                color: GlobalStates.drawerColors

                ElevatedCharging {}
            }

            Rectangle {
                id: bottomBar

                anchors.bottom: parent.bottom
                implicitWidth: QsWindow.window?.width ?? 0
                implicitHeight: exclusiveBottom.zone
                color: GlobalStates.drawerColors

                ElevatedCharging {}
            }
        }

        App {
            id: app
        }

        Bar {
            id: bar
        }

        DynamicIsland {
            id: dynamicIsland
        }

        Clipboard {
            id: clipboard
        }

        Calendar {
            id: cal
            anchors.topMargin: topBar.height
        }

        QuickSettings {
            id: quickSettings
        }

        Session {
            id: session
        }

        WallpaperSelector {}

        Screencapture {}

        ScreenRecorder {}

        OSD {
            id: osd
            anchors.bottomMargin: app.height + Configs.generals.outerBorderSize
        }

        Notifications {
            id: notif
            anchors.topMargin: topBar.height
        }

        Weathers {}

        Volume {
            id: volume
            anchors.rightMargin: session.width + Configs.generals.outerBorderSize
        }

        Rectangle {
            id: cornersArea

            implicitWidth: QsWindow.window?.width - (leftBar.implicitWidth + rightBar.implicitWidth)
            implicitHeight: QsWindow.window?.height - (topBar.implicitHeight + bottomBar.implicitHeight)
            color: "transparent"
            x: leftBar.implicitWidth
            y: topBar.implicitHeight
            z: -2

            Repeater {
                model: [0, 1, 2, 3]
                Cornery {
                    required property int modelData
                    corner: modelData
                    color: GlobalStates.drawerColors
                }
            }
        }
    }

    component Exclusion: PanelWindow {
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }

    component Cornery: WrapperItem {
        id: root

        property alias color: shapePath.fillColor
        property int corner
        property real radius: 20

        Component.onCompleted: {
            switch (corner) {
            case 0:
                anchors.left = parent.left;
                anchors.top = parent.top;
                break;
            case 1:
                anchors.top = parent.top;
                anchors.right = parent.right;
                rotation = 90;
                break;
            case 2:
                anchors.right = parent.right;
                anchors.bottom = parent.bottom;
                rotation = 180;
                break;
            case 3:
                anchors.left = parent.left;
                anchors.bottom = parent.bottom;
                rotation = -90;
                break;
            }
        }

        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                id: shapePath

                strokeWidth: 0
                fillColor: "transparent"
                startX: root.radius
                PathArc {
                    relativeX: -root.radius
                    relativeY: root.radius
                    radiusX: root.radius
                    radiusY: radiusX
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    relativeX: 0
                    relativeY: -root.radius
                }
                PathLine {
                    relativeX: root.radius
                    relativeY: 0
                }
            }
        }
    }

    component ElevatedCharging: Elevation {
        id: elev
        property color c0From
        property color c0To
        property bool c0Active: false
        property real c0Blend: 1.0

        onC0BlendChanged: {
            if (!c0Active)
                return;
            if (c0Blend >= 1) {
                color = c0To;
                c0Active = false;
            } else if (c0Blend > 0) {
                color = Colours.blendColors(c0From, c0To, c0Blend);
            }
        }

        NAnim {
            id: c0Anim
            target: elev
            property: "c0Blend"
            from: 0.0
            to: 1.0
            duration: Appearance.animations.durations.large * 0.8
        }

        property color c1From
        property color c1To
        property bool c1Active: false
        property real c1Blend: 1.0

        onC1BlendChanged: {
            if (!c1Active)
                return;
            if (c1Blend >= 1) {
                color = c1To;
                c1Active = false;
            } else if (c1Blend > 0) {
                color = Colours.blendColors(c1From, c1To, c1Blend);
            }
        }

        NAnim {
            id: c1Anim
            target: elev
            property: "c1Blend"
            from: 0.0
            to: 1.0
            duration: Appearance.animations.durations.large
        }

        anchors.fill: parent
        color: "transparent"
        blur: 0
        spread: 0
        z: -1

        level: 3

        SequentialAnimation {
            id: chargeFlash

            ParallelAnimation {
                ScriptAction {
                    script: {
                        c0Anim.stop();
                        c0From = elev.color;
                        c0To = Colours.m3Colors.m3Green;
                        c0Active = true;
                        c0Blend = 0.0;
                        c0Anim.start();
                    }
                }
                NAnim {
                    target: elev
                    property: "blur"
                    to: Configs.generals.chargingGlowSpread
                    duration: Appearance.animations.durations.large * 0.8
                }
                NAnim {
                    target: elev
                    property: "spread"
                    to: Configs.generals.chargingGlowSpread
                    duration: Appearance.animations.durations.large * 0.8
                }
            }

            PauseAnimation {
                duration: 800
            }

            ParallelAnimation {
                ScriptAction {
                    script: {
                        c1Anim.stop();
                        c1From = elev.color;
                        c1To = "transparent";
                        c1Active = true;
                        c1Blend = 0.0;
                        c1Anim.start();
                    }
                }
                NAnim {
                    target: elev
                    property: "blur"
                    to: 0
                    duration: Appearance.animations.durations.large
                }
                NAnim {
                    target: elev
                    property: "spread"
                    to: 0
                    duration: Appearance.animations.durations.large
                }
            }
        }

        SequentialAnimation {
            id: lowFlash

            ParallelAnimation {
                ScriptAction {
                    script: {
                        c0Anim.stop();
                        c0From = elev.color;
                        c0To = Colours.m3Colors.m3Red;
                        c0Active = true;
                        c0Blend = 0.0;
                        c0Anim.start();
                    }
                }
                NAnim {
                    target: elev
                    property: "blur"
                    to: 20
                    duration: Appearance.animations.durations.large * 0.8
                }
                NAnim {
                    target: elev
                    property: "spread"
                    to: 20
                    duration: Appearance.animations.durations.large * 0.8
                }
            }

            PauseAnimation {
                duration: 800
            }

            ParallelAnimation {
                ScriptAction {
                    script: {
                        c1Anim.stop();
                        c1From = elev.color;
                        c1To = "transparent";
                        c1Active = true;
                        c1Blend = 0.0;
                        c1Anim.start();
                    }
                }
                NAnim {
                    target: elev
                    property: "blur"
                    to: 0
                    duration: Appearance.animations.durations.large
                }
                NAnim {
                    target: elev
                    property: "spread"
                    to: 0
                    duration: Appearance.animations.durations.large
                }
            }
        }

        Connections {
            target: UPower.displayDevice

            function onStateChanged() {
                if (UPower.displayDevice.state === UPowerDeviceState.Charging)
                    chargeFlash.restart();
            }
            function onPercentageChanged() {
                const percentage = Math.round(UPower.displayDevice.percentage * 100);
                const levels = Configs.generals.battery.warnLevels;
                const warn = levels.find(e => e.level === percentage);

                if (warn) {
                    lowFlash.restart();
                    Quickshell.execDetached({
                        command: ["notify-send", "-a", "vast-shell", "-i", warn.icon, warn.title, warn.message, "-u", warn.level === percentage ? warn.urgency : "normal"]
                    });
                }
            }
        }
    }
}
