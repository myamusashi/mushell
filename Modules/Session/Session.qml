pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

Scope {
    id: session

    property int currentIndex: 0
    property bool isSessionOpen: false
    property bool showConfirmDialog: false
    property var pendingAction: null
    property string pendingActionName: ""

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: {
            gc();
        }
    }

    OuterShapeItem {
        id: root

        content: item
        WlrLayershell.keyboardFocus: session.isSessionOpen ? session.showConfirmDialog ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: item

            implicitWidth: session.isSessionOpen ? 80 : 0
            implicitHeight: Hypr.focusedMonitor.height * 0.5

            focus: session.isSessionOpen
            onFocusChanged: {
                if (focus && session.isSessionOpen) {
                    Qt.callLater(() => {
                        let firstIcon = repeater.itemAt(session.currentIndex);
                        if (firstIcon)
                            firstIcon.children[0].forceActiveFocus();
                    });
                }
            }

            Behavior on implicitWidth {
                NAnim {}
            }

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            Shape {
                id: backgroundShape

                property real cornerRadius: Appearance.rounding.normal
                anchors.fill: parent

                ShapePath {
                    fillColor: Themes.m3Colors.m3Background
                    strokeColor: "transparent"
                    strokeWidth: 2
                    startX: 0
                    startY: backgroundShape.cornerRadius

                    PathArc {
                        x: backgroundShape.cornerRadius
                        y: 0
                        radiusX: backgroundShape.cornerRadius
                        radiusY: backgroundShape.cornerRadius
                        direction: PathArc.Clockwise
                    }

                    PathLine {
                        x: backgroundShape.width
                        y: 0
                    }

                    PathLine {
                        x: backgroundShape.width
                        y: backgroundShape.height
                    }

                    PathLine {
                        x: backgroundShape.cornerRadius
                        y: backgroundShape.height
                    }

                    PathArc {
                        x: 0
                        y: backgroundShape.height - backgroundShape.cornerRadius
                        radiusX: backgroundShape.cornerRadius
                        radiusY: backgroundShape.cornerRadius
                        direction: PathArc.Clockwise
                    }

                    PathLine {
                        x: 0
                        y: backgroundShape.cornerRadius
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                visible: session.isSessionOpen
                spacing: 5

                Repeater {
                    id: repeater

                    model: [
                        {
                            "icon": "power_settings_circle",
                            "name": "Shutdown",
                            "action": () => {
                                Quickshell.execDetached({
                                    command: ["sh", "-c", "systemctl poweroff"]
                                });
                            }
                        },
                        {
                            "icon": "restart_alt",
                            "name": "Reboot",
                            "action": () => {
                                Quickshell.execDetached({
                                    command: ["sh", "-c", "systemctl reboot"]
                                });
                            }
                        },
                        {
                            "icon": "sleep",
                            "name": "Sleep",
                            "action": () => {
                                Quickshell.execDetached({
                                    command: ["sh", "-c", "systemctl suspend"]
                                });
                            }
                        },
                        {
                            "icon": "door_open",
                            "name": "Logout",
                            "action": () => {
                                Quickshell.execDetached({
                                    command: ["sh", "-c", "hyprctl dispatch exit"]
                                });
                            }
                        },
                        {
                            "icon": "lock",
                            "name": "Lockscreen",
                            "action": () => {
                                Quickshell.execDetached({
                                    command: ["sh", "-c", "shell ipc call lock lock"]
                                });
                            }
                        }
                    ]

                    delegate: StyledRect {
						id: rectDelegate

                        required property var modelData
                        required property int index
                        property bool isHighlighted: mouseArea.containsMouse || (iconDelegate.focus && rectDelegate.index === session.currentIndex)

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 70

                        property real animProgress: 0
                        property int animationDelay: session.isSessionOpen ? (4 - rectDelegate.index) * 50 : rectDelegate.index * 50

                        Timer {
							id: animTimer

                            interval: rectDelegate.animationDelay
                            running: false
                            onTriggered: rectDelegate.animProgress = session.isSessionOpen ? 1 : 0
                        }

                        Connections {
                            target: session
                            function onIsSessionOpenChanged() {
                                animTimer.restart();
                            }
                        }

                        transform: Translate {
                            x: (1 - rectDelegate.animProgress) * 120
                        }

                        Behavior on animProgress {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }

                        color: isHighlighted ? Themes.withAlpha(Themes.m3Colors.m3Secondary, 0.2) : "transparent"

                        Behavior on color {
                            CAnim {}
                        }

                        MaterialIcon {
                            id: iconDelegate

                            anchors.centerIn: parent
                            color: Themes.m3Colors.m3Primary
                            font.pointSize: Appearance.fonts.large * 3
                            icon: rectDelegate.modelData.icon

                            Connections {
                                target: session
                                function onCurrentIndexChanged() {
                                    if (session.currentIndex === rectDelegate.index)
                                        iconDelegate.forceActiveFocus();
                                }
                            }

                            Keys.onEnterPressed: handleAction()
                            Keys.onReturnPressed: handleAction()
                            Keys.onUpPressed: {
                                if (session.currentIndex > 0)
                                    session.currentIndex--;
                            }
                            Keys.onDownPressed: {
                                if (session.currentIndex < 4)
                                    session.currentIndex++;
                            }
                            Keys.onEscapePressed: session.isSessionOpen = false

                            scale: mouseArea.pressed ? 0.95 : 1.0

                            Behavior on scale {
                                NAnim {}
                            }

                            function handleAction() {
                                session.pendingAction = rectDelegate.modelData.action;
                                session.pendingActionName = rectDelegate.modelData.name + "?";
                                session.showConfirmDialog = true;
                            }

                            MArea {
								id: mouseArea

                                anchors.fill: parent
                                layerColor: "transparent"
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    parent.focus = true;
                                    session.currentIndex = rectDelegate.index;
                                    parent.handleAction();
                                }

                                onEntered: {
                                    parent.focus = true;
                                    session.currentIndex = rectDelegate.index;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    DialogBox {
        id: boxConfirmation

        anchors.centerIn: parent

        header: "Session"
        body: "Do you want to " + session.pendingActionName.toLowerCase()
        active: session.showConfirmDialog

        onAccepted: {
            if (session.pendingAction)
                session.pendingAction();

            session.showConfirmDialog = false;
            session.isSessionOpen = false;
            session.pendingAction = null;
            session.pendingActionName = "";
        }

        onRejected: {
            session.showConfirmDialog = false;
            session.pendingAction = null;
            session.pendingActionName = "";
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            session.isSessionOpen = !session.isSessionOpen;
        }
    }
}
