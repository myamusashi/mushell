pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Components
import qs.Configs
import qs.Services

RowLayout {
    id: root

    property bool isOpen

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: 0

        StyledButton {
            id: mainButton

            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: 56

            buttonTitle: "Shutdown"
            iconButton: "power_settings_circle"
            iconSize: Appearance.fonts.extraLarge
            buttonColor: Colours.m3Colors.m3Primary
            buttonTextColor: Colours.m3Colors.m3OnPrimary
            buttonHeight: 56

            scale: mArea.containsMouse ? 1.05 : 1.0

            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }

            onClicked: {
                Quickshell.execDetached({
                                            "command": ["sh", "-c", "systemctl poweroff"]
                                        });
            }
        }

        Repeater {
            model: [
                {
                    "icon": "restart_alt",
                    "name": "Reboot",
                    "action": () => {
                        Quickshell.execDetached({
                                                    "command": ["sh", "-c", "systemctl reboot"]
                                                });
                    }
                },
                {
                    "icon": "sleep",
                    "name": "Sleep",
                    "action": () => {
                        Quickshell.execDetached({
                                                    "command": ["sh", "-c", "systemctl suspend"]
                                                });
                    }
                },
                {
                    "icon": "door_open",
                    "name": "Logout",
                    "action": () => {
                        Quickshell.execDetached({
                                                    "command": ["sh", "-c", "hyprctl dispatch exit"]
                                                });
                    }
                }
            ]

            delegate: StyledButton {
                id: buttonDelegate

                required property var modelData
                required property int index

                Layout.preferredWidth: mainButton.width
                Layout.preferredHeight: root.isOpen ? 56 : 0
                Layout.topMargin: root.isOpen ? Appearance.spacing.normal : 0

                buttonTitle: modelData.name
                iconButton: modelData.icon
                iconSize: Appearance.fonts.extraLarge
                buttonColor: Colours.m3Colors.m3Primary
                buttonTextColor: Colours.m3Colors.m3OnPrimary
                buttonHeight: 56

                visible: root.isOpen || Layout.preferredHeight > 0
                opacity: root.isOpen ? 1.0 : 0.0
                scale: root.isOpen ? (mArea.containsMouse ? 1.05 : 1.0) : 0.8
                transformOrigin: Item.Center

                Behavior on Layout.preferredHeight {
                    NAnim {
                        duration: Appearance.animations.durations.normal
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                }

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.normal
                        easing.bezierCurve: Appearance.animations.curves.standard
                    }
                }

                Behavior on scale {
                    NAnim {
                        duration: Appearance.animations.durations.normal
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                }

                Behavior on Layout.topMargin {
                    NAnim {
                        duration: Appearance.animations.durations.normal
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                }

                onClicked: modelData.action()
            }
        }
    }

    StyledButton {
        id: toggleButton

        Layout.alignment: Qt.AlignBottom
        Layout.preferredWidth: 56
        Layout.preferredHeight: 56

        iconButton: root.isOpen ? "keyboard_arrow_down" : "keyboard_arrow_up"
        iconSize: Appearance.fonts.extraLarge
        buttonColor: Colours.m3Colors.m3Primary
        buttonTextColor: Colours.m3Colors.m3OnPrimary
        buttonHeight: 56
        baseWidth: 56

        scale: mArea.containsMouse ? 1.1 : 1.0
        backgroundRounding: Appearance.rounding.full

        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.standard
            }
        }

        Item {
            anchors.fill: parent
            rotation: root.isOpen ? 180 : 0

            Behavior on rotation {
                NAnim {
                    duration: Appearance.animations.durations.normal
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }
        }

        onClicked: {
            root.isOpen = !root.isOpen;
        }
    }
}
