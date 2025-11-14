pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

Scope {
    id: session

    property int currentIndex: 0
    property bool isSessionOpen: false
    property bool showConfirmDialog: false
    property var pendingAction: null
    property string pendingActionName: ""

    LazyLoader {
        active: session.isSessionOpen

        component: PanelWindow {
            id: sessionWindow

            visible: session.isSessionOpen
            focusable: true

            anchors.right: true
            margins.right: 10
            exclusiveZone: 0
            implicitWidth: 80
            implicitHeight: 550
            WlrLayershell.namespace: "shell:session"
            color: "transparent"

            Item {
                anchors.fill: parent

                StyledRect {
                    anchors.fill: parent

                    radius: Appearance.rounding.normal
                    color: Themes.colors.background
                    border.color: Themes.colors.outline
                    border.width: 2

                    ColumnLayout {
                        anchors.fill: parent

                        anchors.margins: 10
                        spacing: 5

                        Repeater {
                            model: [{
                                    "icon": "power_settings_circle",
                                    "name": "Shutdown",
                                    "action": () => {
                                        Quickshell.execDetached({
                                                                    "command": ["sh", "-c", "systemctl poweroff"]
                                                                })
                                    }
                                }, {
                                    "icon": "restart_alt",
                                    "name": "Reboot",
                                    "action": () => {
                                        Quickshell.execDetached({
                                                                    "command": ["sh", "-c", "systemctl reboot"]
                                                                })
                                    }
                                }, {
                                    "icon": "sleep",
                                    "name": "Sleep",
                                    "action": () => {
                                        Quickshell.execDetached({
                                                                    "command": ["sh", "-c", "systemctl suspend"]
                                                                })
                                    }
                                }, {
                                    "icon": "door_open",
                                    "name": "Logout",
                                    "action": () => {
                                        Quickshell.execDetached({
                                                                    "command": ["sh", "-c", "hyprctl dispatch exit"]
                                                                })
                                    }
                                }, {
                                    "icon": "lock",
                                    "name": "Lockscreen",
                                    "action": () => {
                                        Quickshell.execDetached({
                                                                    "command": ["sh", "-c", "shell ipc call lock lock"]
                                                                })
                                    }
                                }]

                            delegate: StyledRect {
                                id: rectDelegate

                                required property var modelData
                                required property int index
                                property bool isHighlighted: mouseArea.containsMouse
                                                             || (iconDelegate.focus
                                                                 && rectDelegate.index
                                                                 === session.currentIndex)

                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 70

                                radius: Appearance.rounding.normal
                                color: isHighlighted ? Themes.withAlpha(
                                                           Themes.colors.secondary,
                                                           0.2) : "transparent"

                                Behavior on color {
                                    ColAnim {}
                                }

                                MatIcon {
                                    id: iconDelegate

                                    anchors.centerIn: parent
                                    color: Themes.colors.primary
                                    font.pixelSize: Appearance.fonts.large * 4
                                    icon: rectDelegate.modelData.icon

                                    focus: rectDelegate.index === session.currentIndex

                                    Keys.onEnterPressed: handleAction()
                                    Keys.onReturnPressed: handleAction()
                                    Keys.onUpPressed: {
                                        if (session.currentIndex > 0)
                                        session.currentIndex--
                                    }
                                    Keys.onDownPressed: {
                                        if (session.currentIndex < 4)
                                        session.currentIndex++
                                    }
                                    Keys.onEscapePressed: session.isSessionOpen = false

                                    scale: mouseArea.pressed ? 0.95 : 1.0

                                    Behavior on scale {
                                        NumbAnim {}
                                    }

                                    function handleAction() {
                                        session.pendingAction = rectDelegate.modelData.action
                                        session.pendingActionName
                                                = rectDelegate.modelData.name + "?"
                                        session.showConfirmDialog = true
                                    }

                                    MArea {
                                        id: mouseArea

                                        anchors.fill: parent

                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true

                                        onClicked: {
                                            parent.focus = true
                                            session.currentIndex = rectDelegate.index
                                            parent.handleAction()
                                        }

                                        onEntered: {
                                            parent.focus = true
                                            session.currentIndex = rectDelegate.index
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
                        session.pendingAction()

                        session.showConfirmDialog = false
                        session.isSessionOpen = false
                        session.pendingAction = null
                        session.pendingActionName = ""
                    }

                    onRejected: {
                        session.showConfirmDialog = false
                        session.pendingAction = null
                        session.pendingActionName = ""
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            session.isSessionOpen = !session.isSessionOpen
        }
    }
}
