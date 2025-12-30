pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import "Calendar"
import "Launcher"
import "MediaPlayer"
import "QuickSettings"
import "Overview"
import "Notifications"
import "Session"
import "Wallpaper"
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
        property alias top: topBar
        property alias bottom: bottomBar
        property alias left: leftBar
        property alias right: rightBar

        screen: modelData
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
                screen: window.modelData
                name: "left"
                exclusiveZone: leftBar.implicitWidth
                anchors.left: true
            }
            Exclusion {
                screen: window.modelData
                name: "top"
                exclusiveZone: topBar.implicitHeight
                anchors.top: true
            }
            Exclusion {
                screen: window.modelData
                name: "right"
                exclusiveZone: rightBar.implicitWidth
                anchors.right: true
            }
            Exclusion {
                screen: window.modelData
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

                implicitWidth: GlobalStates.hideOuterBorder ? 0 : 5
                implicitHeight: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.height ?? 0
                color: window.barColor
                anchors.left: parent.left

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            Rectangle {
                id: topBar

                implicitWidth: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.width ?? 0
                implicitHeight: GlobalStates.hideOuterBorder ? 0 : 5
                color: window.barColor
                anchors.top: parent.top

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            Rectangle {
                id: rightBar

                implicitWidth: GlobalStates.hideOuterBorder ? 0 : 5
                implicitHeight: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.height ?? 0
                color: window.barColor
                anchors.right: parent.right

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            Rectangle {
                id: bottomBar

                implicitWidth: GlobalStates.hideOuterBorder ? 0 : QsWindow.window?.width ?? 0
                implicitHeight: GlobalStates.hideOuterBorder ? 0 : 5
                color: window.barColor
                anchors.bottom: parent.bottom

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }
        }

        App {
            id: app
        }

        Bar {
            id: bar

            onHeightChanged: {
                topBar.implicitHeight = bar.height;
                cal.anchors.topMargin = bar.height;
                mediaPlayer.anchors.topMargin = bar.height;
                quickSettings.anchors.topMargin = bar.height;
				notif.anchors.topMargin = bar.height;
				weathers.anchors.topMargin = bar.height;
                // notifCenter.anchors.topMargin = bar.height;
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
            GlobalShortcut {
                name: "overview"
                onPressed: GlobalStates.isOverviewOpen = !GlobalStates.isOverviewOpen
            }
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
        property real radius: 5
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
