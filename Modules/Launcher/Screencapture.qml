pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import Quickshell

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Scope {
    id: root

    IpcHandler {
        target: "screencapture"

        function toggle(): void {
            GlobalStates.isScreenCapturePanelOpen = !GlobalStates.isScreenCapturePanelOpen;
        }
    }

    GlobalShortcut {
        name: "screencaptureLauncher"
        onPressed: GlobalStates.isScreenCapturePanelOpen = !GlobalStates.isScreenCapturePanelOpen
    }

    LazyLoader {
        activeAsync: GlobalStates.isScreenCapturePanelOpen

        component: PanelWindow {
            id: window

            property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
            property real monitorWidth: monitor.width / monitor.scale
            property real monitorHeight: monitor.height / monitor.scale
            property int selectedIndex: 0
            property int selectedTab: 0

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "shell:capture"

            anchors {
                right: true
                left: true
            }

            implicitWidth: monitorWidth * 0.18
            implicitHeight: monitorHeight * 0.35
            margins.right: monitorWidth * 0.41
            margins.left: monitorWidth * 0.41

            color: "transparent"

            Loader {
                anchors.fill: parent
                active: GlobalStates.isScreenCapturePanelOpen
                asynchronous: true
                sourceComponent: Item {
                    anchors.fill: parent

                    StyledRect {
                        id: container

                        anchors.fill: parent
                        radius: Appearance.rounding.large
                        color: Colours.m3Colors.m3Background
                        border.color: Colours.m3Colors.m3Outline
                        border.width: 2

                        readonly property int contentPadding: Appearance.spacing.normal

                        Keys.onPressed: function (event) {
                            switch (event.key) {
                            case Qt.Key_Tab:
                                window.selectedTab = (window.selectedTab + 1) % 2;
                                event.accepted = true;
                                break;
                            case Qt.Key_Up:
                                window.selectedTab === 0 ? 4 : 2;
                                window.selectedIndex = Math.max(0, window.selectedIndex - 1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Backtab:
                                window.selectedTab = (window.selectedTab - 1 + 2) % 2;
                                event.accepted = true;
                                break;
                            case Qt.Key_Down:
                                const maxIndex = window.selectedTab === 0 ? 4 : 2;
                                window.selectedIndex = Math.min(maxIndex, window.selectedIndex + 1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                const repeater = window.selectedTab === 0 ? screenshotRepeater : recordRepeater;
                                const item = repeater.itemAt(window.selectedIndex);
                                if (item && item.optionData.action) {
                                    item.optionData.action();
                                    GlobalStates.isScreenCapturePanelOpen = false;
                                }
                                event.accepted = true;
                                break;
                            case Qt.Key_Escape:
                                GlobalStates.isScreenCapturePanelOpen = false;
                                event.accepted = true;
                                break;
                            }
                        }

                        Connections {
                            target: window

                            function onSelectedTabChanged() {
                                window.selectedIndex = 0;
                            }
                        }

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

                                        focus: GlobalStates.isScreenCapturePanelOpen
                                        onFocusChanged: {
                                            if (focus && GlobalStates.isScreenCapturePanelOpen)
                                            Qt.callLater(() => {
                                                             let firstIcon = tabRepeater.itemAt(window.selectedTab);
                                                             if (firstIcon)
                                                             firstIcon.children[0].forceActiveFocus();
                                                         });
                                        }

                                        radius: index === 0 ? Qt.vector4d(Appearance.rounding.normal, Appearance.rounding.normal, 0, 0) : Qt.vector4d(Appearance.rounding.normal, Appearance.rounding.normal, 0, 0)

                                        color: isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Surface

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: tabItem.modelData
                                            color: tabItem.isSelected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3Outline
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
                                                "name": "Window",
                                                "icon": "select_window_2",
                                                "action": () => {
                                                    Quickshell.execDetached({
                                                                                "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-window"]
                                                                            });
                                                }
                                            },
                                            {
                                                "name": "Selection",
                                                "icon": "select",
                                                "action": () => {
                                                    Quickshell.execDetached({
                                                                                "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-selection"]
                                                                            });
                                                }
                                            },
                                            {
                                                "name": "eDP-1",
                                                "icon": "monitor",
                                                "action": () => {
                                                    Quickshell.execDetached({
                                                                                "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-eDP-1"]
                                                                            });
                                                }
                                            },
                                            {
                                                "name": "HDMI-A-2",
                                                "icon": "monitor",
                                                "action": () => {
                                                    Quickshell.execDetached({
                                                                                "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-HDMI-A-2"]
                                                                            });
                                                }
                                            },
                                            {
                                                "name": "Both Screens",
                                                "icon": "dual_screen",
                                                "action": () => {
                                                    Quickshell.execDetached({
                                                                                "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-both-screens"]
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
                                            isSelected: index === window.selectedIndex && window.selectedTab === 0
                                            maxIndex: 4

                                            onIndexModel: function (idx) {
                                                window.selectedIndex = idx;
                                            }

                                            onClosed: GlobalStates.isScreenCapturePanelOpen = false
                                        }
                                    }
                                }

                                ColumnLayout {
                                    spacing: Appearance.spacing.small

                                    Repeater {
                                        id: recordRepeater

                                        model: [
                                            {
                                                "name": "Selection",
                                                "icon": "select",
                                                "action": () => {
                                                    Quickshell.execDetached({
                                                                                "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-selection"]
                                                                            });
                                                }
                                            },
                                            {
                                                "name": "eDP-1",
                                                "icon": "monitor",
                                                "action": () => {
                                                    Quickshell.execDetached({
                                                                                "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-eDP-1"]
                                                                            });
                                                }
                                            },
                                            {
                                                "name": "HDMI-A-2",
                                                "icon": "monitor",
                                                "action": () => {
                                                    Quickshell.execDetached({
                                                                                "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-HDMI-A-2"]
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
                                            isSelected: index === window.selectedIndex && window.selectedTab === 1
                                            maxIndex: 2

                                            onIndexModel: function (idx) {
                                                window.selectedIndex = idx;
                                            }

                                            onClosed: GlobalStates.isScreenCapturePanelOpen = false
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
}
