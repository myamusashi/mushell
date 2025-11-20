pragma ComponentBehavior: Bound

import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import "../RecordControl"
import qs.Components

Scope {
    id: root

    property int selectedIndex: 0
    property bool isOpen: false
    property string scriptPath: `${Quickshell.shellDir}/Assets/screen-capture.sh`

    GlobalShortcut {
        name: "screencaptureLauncher"
        onPressed: root.isOpen = !root.isOpen
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: {
            gc();
        }
    }

    LazyLoader {
        active: root.isOpen
        onActiveChanged: {
            cleanup.start();
        }

        component: PanelWindow {
            id: window

            property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
            property real monitorWidth: monitor.width / monitor.scale
            property real monitorHeight: monitor.height / monitor.scale
            property int selectedTab: 0

            visible: root.isOpen
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

            Item {
                anchors.fill: parent

                StyledRect {
                    id: container

                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Themes.m3Colors.m3Background
                    border.color: Themes.m3Colors.m3Outline
                    border.width: 2

                    readonly property int contentPadding: Appearance.spacing.normal

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: container.contentPadding
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Repeater {
                                id: tabRepeater
                                model: ["Screenshot", "Screen record"]

                                delegate: StyledRect {
                                    id: tabItem

                                    required property string modelData
                                    required property int index

                                    readonly property bool isSelected: window.selectedTab === index

                                    Layout.fillWidth: true
									Layout.preferredHeight: 32

									Keys.onTabPressed: window.selectedTab = tabItem.index

                                    radius: index === 0 ? Qt.vector4d(Appearance.rounding.normal, Appearance.rounding.normal, 0, 0) : Qt.vector4d(Appearance.rounding.normal, Appearance.rounding.normal, 0, 0)

                                    color: isSelected ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3Surface

                                    Behavior on color {
                                        CAnim {
                                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                        }
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: tabItem.modelData
                                        color: tabItem.isSelected ? Themes.m3Colors.m3OnPrimary : Themes.m3Colors.m3Outline
                                        font.pixelSize: Appearance.fonts.normal * 0.9
                                        font.bold: tabItem.isSelected
                                    }

                                    MArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.selectedTab = tabItem.index
                                    }
                                }
                            }
                        }

                        StackLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            currentIndex: window.selectedTab

                            ColumnLayout {
                                spacing: Appearance.spacing.small

                                Repeater {
                                    id: screenshotRepeater

                                    model: [
                                        {
                                            name: "Window",
                                            icon: "select_window_2",
                                            action: () => {
                                                Quickshell.execDetached({
                                                    command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-window"]
                                                });
                                            }
                                        },
                                        {
                                            name: "Selection",
                                            icon: "select",
                                            action: () => {
                                                Quickshell.execDetached({
                                                    command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-selection"]
                                                });
                                            }
                                        },
                                        {
                                            name: "eDP-1",
                                            icon: "monitor",
                                            action: () => {
                                                Quickshell.execDetached({
                                                    command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-eDP-1"]
                                                });
                                            }
                                        },
                                        {
                                            name: "HDMI-A-2",
                                            icon: "monitor",
                                            action: () => {
                                                Quickshell.execDetached({
                                                    command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-HDMI-A-2"]
                                                });
                                            }
                                        },
                                        {
                                            name: "Both Screens",
                                            icon: "dual_screen",
                                            action: () => {
                                                Quickshell.execDetached({
                                                    command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-both-screens"]
                                                });
                                            }
                                        }
                                    ]

                                    delegate: CaptureItem {
                                        required property var modelData
                                        required property int index

                                        Layout.preferredHeight: 38
                                        Layout.fillWidth: true
                                        optionData: modelData
                                        optionIndex: index
                                        isSelected: index === root.selectedIndex && window.selectedTab === 0
                                        maxIndex: 4

                                        onIndexModel: function (idx) {
                                            root.selectedIndex = idx;
                                        }

                                        onClosed: root.isOpen = false
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: Appearance.spacing.small

                                Repeater {
                                    id: recordRepeater

                                    model: [
                                        {
                                            name: "Selection",
                                            icon: "select",
                                            action: () => {
                                                Quickshell.execDetached({
                                                    command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-selection"]
                                                });
                                            }
                                        },
                                        {
                                            name: "eDP-1",
                                            icon: "monitor",
                                            action: () => {
                                                Quickshell.execDetached({
                                                    command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-eDP-1"]
                                                });
                                            }
                                        },
                                        {
                                            name: "HDMI-A-2",
                                            icon: "monitor",
                                            action: () => {
                                                Quickshell.execDetached({
                                                    command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-HDMI-A-2"]
                                                });
                                            }
                                        }
                                    ]

                                    delegate: CaptureItem {
                                        required property var modelData
                                        required property int index
                                        Layout.preferredHeight: 38
                                        Layout.fillWidth: true
                                        optionData: modelData
                                        optionIndex: index
                                        isSelected: index === root.selectedIndex && window.selectedTab === 0
                                        maxIndex: 3

                                        onIndexModel: function (idx) {
                                            root.selectedIndex = idx;
                                        }

                                        onClosed: root.isOpen = false
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
            root.isOpen = !root.isOpen;
        }
    }
}
