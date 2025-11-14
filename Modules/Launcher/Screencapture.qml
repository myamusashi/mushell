pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import "../RecordControl"
import qs.Components

Scope {
    id: screencapture

    property int currentIndex: 0
    property bool isScreencaptureOpen: false
    property string scriptPath: `${Quickshell.shellDir}/Assets/screen-capture.sh`

    GlobalShortcut {
        name: "screencaptureLauncher"
        onPressed: screencapture.isScreencaptureOpen = !screencapture.isScreencaptureOpen
    }

    LazyLoader {
        active: screencapture.isScreencaptureOpen

        component: PanelWindow {
            id: captureWindow

            property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
            property real monitorWidth: monitor.width / monitor.scale
            property real monitorHeight: monitor.height / monitor.scale

            visible: screencapture.isScreencaptureOpen
            focusable: true

            anchors {
                right: true
                left: true
            }

            WlrLayershell.namespace: "shell:capture"

            implicitWidth: monitorWidth * 0.18
            implicitHeight: monitorHeight * 0.35
            margins.right: monitorWidth * 0.41
            margins.left: monitorWidth * 0.41

            color: "transparent"

            property int activeTab: 0

            Item {
                anchors.fill: parent

                StyledRect {
                    anchors.fill: parent

                    radius: Appearance.rounding.large
                    color: Themes.colors.background
                    border.color: Themes.colors.outline
                    border.width: 2

                    property int padding: Appearance.spacing.normal

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: parent.padding
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Repeater {
                                model: ["Screenshot", "Screen record"]

                                delegate: StyledRect {
                                    id: tabButton

                                    required property string modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32

                                    radius: index === 0 ? Qt.vector4d(
                                                              Appearance.rounding.normal,
                                                              Appearance.rounding.normal,
                                                              0,
                                                              0) : Qt.vector4d(
                                                              Appearance.rounding.normal,
                                                              Appearance.rounding.normal,
                                                              0, 0)

                                    color: captureWindow.activeTab
                                           === index ? Themes.colors.primary : Themes.colors.surface

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: tabButton.modelData
                                        color: captureWindow.activeTab === tabButton.index ? Themes.colors.on_primary : Themes.colors.outline

                                        font.pixelSize: Appearance.fonts.normal * 0.9
                                        font.bold: captureWindow.activeTab === tabButton.index
                                    }

                                    MArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: captureWindow.activeTab = tabButton.index
                                    }

                                    Behavior on color {
                                        ColAnim {
                                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                        }
                                    }
                                }
                            }
                        }

                        StackLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            currentIndex: captureWindow.activeTab

                            ColumnLayout {
                                spacing: Appearance.spacing.small

                                Repeater {
                                    model: [{
                                            "name": "Window",
                                            "icon": "select_window_2",
                                            "action": () => {
                                                Quickshell.execDetached({
                                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-window"]
                                                                        })
                                            }
                                        }, {
                                            "name": "Selection",
                                            "icon": "select",
                                            "action": () => {
                                                Quickshell.execDetached({
                                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-selection"]
                                                                        })
                                            }
                                        }, {
                                            "name": "eDP-1",
                                            "icon": "monitor",
                                            "action": () => {
                                                Quickshell.execDetached({
                                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-eDP-1"]
                                                                        })
                                            }
                                        }, {
                                            "name": "HDMI-A-2",
                                            "icon": "monitor",
                                            "action": () => {
                                                Quickshell.execDetached({
                                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-HDMI-A-2"]
                                                                        })
                                            }
                                        }, {
                                            "name": "Both Screens",
                                            "icon": "dual_screen",
                                            "action": () => {
                                                Quickshell.execDetached({
                                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-both-screens"]
                                                                        })
                                            }
                                        }]

                                    delegate: StyledRect {
                                        id: iconDelegate1

                                        required property var modelData
                                        required property int index

                                        Layout.preferredHeight: 38
                                        Layout.fillWidth: true

                                        RowLayout {
                                            id: rowIndex1

                                            anchors.fill: parent
                                            anchors.leftMargin: Appearance.spacing.small
                                            anchors.rightMargin: Appearance.spacing.small

                                            spacing: Appearance.spacing.normal

                                            focus: iconDelegate1.index
                                                   === screencapture.currentIndex
                                                   && captureWindow.activeTab === 0
                                            Keys.onEnterPressed: {
                                                iconDelegate1.modelData.action()
                                                screencapture.isScreencaptureOpen = false
                                            }
                                            Keys.onReturnPressed: {
                                                iconDelegate1.modelData.action()
                                                screencapture.isScreencaptureOpen = false
                                            }
                                            Keys.onUpPressed: screencapture.currentIndex > 0 ? screencapture.currentIndex-- : ""
                                            Keys.onDownPressed: screencapture.currentIndex < 4 ? screencapture.currentIndex++ : ""
                                            Keys.onEscapePressed: screencapture.isScreencaptureOpen = !screencapture.isScreencaptureOpen

                                            transform: Scale {
                                                id: scaleTransform1

                                                origin.x: rowIndex1.width / 2
                                                origin.y: rowIndex1.height / 2
                                                xScale: iconDelegate1.index
                                                        === screencapture.currentIndex
                                                        && captureWindow.activeTab
                                                        === 0 ? 1.03 : 1.0
                                                yScale: iconDelegate1.index
                                                        === screencapture.currentIndex
                                                        && captureWindow.activeTab
                                                        === 0 ? 1.03 : 1.0

                                                Behavior on xScale {
                                                    NumbAnim {
                                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                                    }
                                                }
                                                Behavior on yScale {
                                                    NumbAnim {
                                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                                    }
                                                }
                                            }

                                            MatIcon {
                                                id: icon1

                                                icon: iconDelegate1.modelData.icon
                                                color: iconDelegate1.index
                                                       === screencapture.currentIndex
                                                       && captureWindow.activeTab === 0 ? Themes.colors.primary : Themes.colors.outline
                                                font.pixelSize: Appearance.fonts.large
                                                Layout.alignment: Qt.AlignVCenter

                                                Behavior on color {
                                                    ColAnim {
                                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                                    }
                                                }
                                            }

                                            StyledText {
                                                id: name1

                                                color: iconDelegate1.index
                                                       === screencapture.currentIndex
                                                       && captureWindow.activeTab === 0 ? Themes.colors.primary : Themes.colors.outline
                                                font.pixelSize: Appearance.fonts.normal
                                                text: iconDelegate1.modelData.name
                                                Layout.fillWidth: true
                                            }
                                        }
                                        MArea {
                                            id: mArea1

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true

                                            onClicked: {
                                                icon1.focus = true
                                                iconDelegate1.modelData.action()
                                                screencapture.isScreencaptureOpen = false
                                            }
                                            onEntered: parent.focus = true
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: Appearance.spacing.small

                                Repeater {
                                    model: [{
                                            "name": "Selection",
                                            "icon": "select",
                                            "action": () => {
                                                Quickshell.execDetached({
                                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-selection"]
                                                                        })
                                            }
                                        }, {
                                            "name": "eDP-1",
                                            "icon": "monitor",
                                            "action": () => {
                                                Quickshell.execDetached({
                                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-eDP-1"]
                                                                        })
                                            }
                                        }, {
                                            "name": "HDMI-A-2",
                                            "icon": "monitor",
                                            "action": () => {
                                                Quickshell.execDetached({
                                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-HDMI-A-2"]
                                                                        })
                                            }
                                        }]

                                    delegate: StyledRect {
                                        id: iconDelegate2

                                        required property var modelData
                                        required property int index

                                        Layout.preferredHeight: 38
                                        Layout.fillWidth: true

                                        RowLayout {
                                            id: rowIndex2

                                            anchors.fill: parent
                                            anchors.leftMargin: Appearance.spacing.small
                                            anchors.rightMargin: Appearance.spacing.small

                                            spacing: Appearance.spacing.normal

                                            focus: iconDelegate2.index
                                                   === screencapture.currentIndex
                                                   && captureWindow.activeTab === 1
                                            Keys.onEnterPressed: {
                                                iconDelegate2.modelData.action()
                                                screencapture.isScreencaptureOpen = false
                                            }
                                            Keys.onReturnPressed: {
                                                iconDelegate2.modelData.action()
                                                screencapture.isScreencaptureOpen = false
                                            }
                                            Keys.onUpPressed: screencapture.currentIndex > 0 ? screencapture.currentIndex-- : ""
                                            Keys.onDownPressed: screencapture.currentIndex < 2 ? screencapture.currentIndex++ : ""
                                            Keys.onEscapePressed: screencapture.isScreencaptureOpen = !screencapture.isScreencaptureOpen

                                            transform: Scale {
                                                id: scaleTransform2

                                                origin.x: rowIndex2.width / 2
                                                origin.y: rowIndex2.height / 2
                                                xScale: iconDelegate2.index
                                                        === screencapture.currentIndex
                                                        && captureWindow.activeTab
                                                        === 1 ? 1.03 : 1.0
                                                yScale: iconDelegate2.index
                                                        === screencapture.currentIndex
                                                        && captureWindow.activeTab
                                                        === 1 ? 1.03 : 1.0

                                                Behavior on xScale {
                                                    NumbAnim {
                                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                                    }
                                                }
                                                Behavior on yScale {
                                                    NumbAnim {
                                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                                    }
                                                }
                                            }

                                            MatIcon {
                                                id: icon2

                                                icon: iconDelegate2.modelData.icon
                                                color: iconDelegate2.index
                                                       === screencapture.currentIndex
                                                       && captureWindow.activeTab === 1 ? Themes.colors.primary : Themes.colors.outline
                                                font.pixelSize: Appearance.fonts.large
                                                Layout.alignment: Qt.AlignVCenter

                                                Behavior on color {
                                                    ColAnim {
                                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                                    }
                                                }
                                            }

                                            StyledText {
                                                id: name2

                                                color: iconDelegate2.index
                                                       === screencapture.currentIndex
                                                       && captureWindow.activeTab === 1 ? Themes.colors.primary : Themes.colors.outline
                                                font.pixelSize: Appearance.fonts.normal
                                                text: iconDelegate2.modelData.name
                                                Layout.fillWidth: true
                                            }
                                        }
                                        MArea {
                                            id: mArea2

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true

                                            onClicked: {
                                                icon2.focus = true
                                                iconDelegate2.modelData.action()
                                                recordControl.isRecordingControlOpen = true
                                                screencapture.isScreencaptureOpen = false
                                            }
                                            onEntered: parent.focus = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RecordControl {
        id: recordControl
    }

    IpcHandler {
        target: "screencapture"

        function toggle(): void {
            screencapture.isScreencaptureOpen = !screencapture.isScreencaptureOpen
        }
    }
}
