import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Core.Configs
import qs.Core.States
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
import "Brightness"
import "ScreenRecorder"

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
        HyprlandWindow.visibleMask: childRegions.instances
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
                implicitHeight: QsWindow.window?.height ?? 0 // qmllint disable
                color: GlobalStates.drawerColors

                ElevatedCharging {}
            }

            Rectangle {
                id: topBar

                anchors.top: parent.top
                implicitWidth: QsWindow.window?.width ?? 0 // qmllint disable
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
                implicitHeight: QsWindow.window?.height ?? 0 // qmllint disable
                color: GlobalStates.drawerColors

                ElevatedCharging {}
            }

            Rectangle {
                id: bottomBar

                anchors.bottom: parent.bottom
                implicitWidth: QsWindow.window?.width ?? 0 // qmllint disable
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
        }

        BrightnessOsd {
            id: brightnessOsd
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

            implicitWidth: QsWindow.window?.width - (leftBar.implicitWidth + rightBar.implicitWidth) // qmllint disable
            implicitHeight: QsWindow.window?.height - (topBar.implicitHeight + bottomBar.implicitHeight) // qmllint disable
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

    component Exclusion: PanelWindow { // qmllint disable
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }
}
