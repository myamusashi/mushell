pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import "Calendar"
import "Launcher"
import "MediaPlayer"
import "QuickSettings"
import "Notifications"
import "Session"
import "Wallpaper"
import "OSD"
import "Bar"
Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: window

        property bool needFocusKeyboard: false
        property color barColor: Colours.m3Colors.m3Background
        property alias top: topBar
        property alias bottom: bottomBar
        property alias left: leftBar
        property alias right: rightBar

        color: session.isSessionOpen ? Colours.withAlpha(Colours.m3Colors.m3Background, 0.7) : "transparent"
        exclusionMode: ExclusionMode.Ignore
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
            regions: regions.instances
            item: cornersArea
            intersection: Intersection.Subtract
        }

        Variants {
            id: regions

            model: window.contentItem.children
            delegate: Region {
                required property Item modelData
                item: modelData
                intersection: Intersection.Xor
            }
        }

        Scope {
            Exclusion {
                name: "left"
                exclusiveZone: leftBar.implicitWidth
                anchors.left: true
            }
            Exclusion {
                name: "top"
                exclusiveZone: topBar.implicitHeight
                anchors.top: true
            }
            Exclusion {
                name: "right"
                exclusiveZone: rightBar.implicitWidth
                anchors.right: true
            }
            Exclusion {
                name: "bottom"
                exclusiveZone: bottomBar.implicitHeight
                anchors.bottom: true
            }
        }

        Rectangle {
            id: rect

            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: leftBar

                implicitWidth: GlobalStates.hideOuterBorder ? 0 : 10
                implicitHeight: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.height ?? 0
                color: window.barColor
                anchors.left: parent.left

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.large
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            Rectangle {
                id: topBar

                implicitWidth: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.width ?? 0
                implicitHeight: GlobalStates.hideOuterBorder ? 0 : 10
                color: window.barColor
                anchors.top: parent.top

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.large
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            Rectangle {
                id: rightBar

                implicitWidth: GlobalStates.hideOuterBorder ? 0 : 10
                implicitHeight: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.height ?? 0
                color: window.barColor
                anchors.right: parent.right

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.large
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            Rectangle {
                id: bottomBar

                implicitWidth: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.width ?? 0
                implicitHeight: GlobalStates.hideOuterBorder ? 0 : 10
                color: window.barColor
                anchors.bottom: parent.bottom

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.large
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }
        }

        App {
            id: app

            onIsLauncherOpenChanged: app.isLauncherOpen ? window.needFocusKeyboard = true : window.needFocusKeyboard = false
        }

        Bar {
            id: bar

            onHeightChanged: {
                topBar.implicitHeight = bar.height;
                cal.anchors.topMargin = bar.height;
                mediaPlayer.anchors.topMargin = bar.height;
                quickSettings.anchors.topMargin = bar.height;
                notif.anchors.topMargin = bar.height;
                notifCenter.anchors.topMargin = bar.height;
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

            onIsSessionOpenChanged: session.isSessionOpen ? window.needFocusKeyboard = true : window.needFocusKeyboard = false
            onShowConfirmDialogChanged: session.showConfirmDialog ? window.needFocusKeyboard = false : window.needFocusKeyboard = true
        }

        WallpaperSelector {
            id: wallpaperSelector

            onIsWallpaperSwitcherOpenChanged: wallpaperSelector.isWallpaperSwitcherOpen ? window.needFocusKeyboard = true : window.needFocusKeyboard = false
        }

        Notifications {
            id: notif
        }

        NotificationCenter {
            id: notifCenter
        }

        OSD {
            id: osd
        }

        Rectangle {
            id: cornersArea

            implicitWidth: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.width - (leftBar.implicitWidth + rightBar.implicitWidth)
            implicitHeight: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.height - (topBar.implicitHeight + bottomBar.implicitHeight)
            color: "transparent"
            x: leftBar.implicitWidth
            y: topBar.implicitHeight

            Repeater {
                model: [0, 1, 2, 3]
                Corner {
                    required property int modelData
                    corner: modelData
                    color: window.barColor
                }
            }
        }
    }

    component Corner: WrapperItem {
        id: root

        property int corner
        property real radius: 20
        property color color

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
                strokeWidth: 0
                fillColor: root.color
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

    component Exclusion: PanelWindow {
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }
}
