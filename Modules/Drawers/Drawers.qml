import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

import qs.Helpers
import qs.Services
import qs.Components

import "Calendar"
import "Launcher"
import "MediaPlayer"
import "QuickSettings"
import "Overview"
import "Notifications"
import "Session"
import "WallpaperSelector"
import "Weather"
import "OSD"
import "Bar"

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: window

        required property ShellScreen modelData
        readonly property bool needFocusKeyboard: {
            if (app.isLauncherOpen)
                return true;
            if (session.isSessionOpen && !session.showConfirmDialog)
                return true;
            if (wallpaperSelector.isWallpaperSwitcherOpen)
                return true;
            if (screenCapture.isScreenCapturePanelOpen)
                return true;
            return false;
        }
        property color barColor: Colours.m3Colors.m3Background

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "shell:drawers"
        WlrLayershell.keyboardFocus: needFocusKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            left: true
            top: true
            right: true
            bottom: true
        }

        Behavior on color {
            CAnim {}
        }

        mask: Region {
            regions: childRegions.instances
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
                screen: window.modelData
                name: "left"
                exclusiveZone: 0
                anchors.left: true
            }
            Exclusion {
                screen: window.modelData
                name: "top"
                exclusiveZone: GlobalStates.isBarOpen ? 40 : 0
                anchors.top: true
            }
            Exclusion {
                screen: window.modelData
                name: "right"
                exclusiveZone: 0
                anchors.right: true
            }
            Exclusion {
                screen: window.modelData
                name: "bottom"
                exclusiveZone: 0
                anchors.bottom: true
            }
        }

        App {
            id: app
        }

        Bar {
            id: bar

            onHeightChanged: {
                cal.anchors.topMargin = bar.height;
                mediaPlayer.anchors.topMargin = bar.height;
                quickSettings.anchors.topMargin = bar.height;
                notif.anchors.topMargin = bar.height;
                weathers.anchors.topMargin = bar.height;
            }
        }

        Calendar {
            id: cal
        }

        MediaPlayer {
            id: mediaPlayer
        }

        QuickSettings {
            id: quickSettings
        }

        Session {
            id: session
        }

        WallpaperSelector {
            id: wallpaperSelector
        }

        Screencapture {
            id: screenCapture
        }

        Overview {
            id: overview
        }

        Notifications {
            id: notif
        }

        Weathers {
            id: weathers
        }

        OSD {
            id: osd
        }
    }

    component Exclusion: PanelWindow {
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }
}
