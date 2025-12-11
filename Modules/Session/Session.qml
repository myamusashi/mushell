pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: root

    property alias dialog: boxConfirmation
    property int currentIndex: 0
    property bool isSessionOpen: GlobalStates.isSessionOpen
    property bool showConfirmDialog: false
    property var pendingAction: null
    property string pendingActionName: ""

    GlobalShortcut {
        name: "session"
        onPressed: root.isSessionOpen = !root.isSessionOpen
    }

    implicitWidth: isSessionOpen ? 80 : 0
    implicitHeight: Hypr.focusedMonitor.height * 0.5
    radius: 0
    topLeftRadius: Appearance.rounding.normal
    bottomLeftRadius: Appearance.rounding.normal
    color: Colours.m3Colors.m3Background

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
    }

    Loader {
        anchors.fill: parent
        active: root.isSessionOpen
        asynchronous: true
        sourceComponent: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: Appearance.spacing.normal

            Repeater {
                id: repeater

                model: [
                    {
                        "icon": "power_settings_circle",
                        "name": "Shutdown",
                        "action": () => {
                            Quickshell.execDetached({
                                                        "command": ["sh", "-c", "systemctl poweroff"]
                                                    });
                        }
                    },
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
                    },
                    {
                        "icon": "lock",
                        "name": "Lockscreen",
                        "action": () => {
                            Quickshell.execDetached({
                                                        "command": ["sh", "-c", "shell ipc call lock lock"]
                                                    });
                        }
                    }
                ]

                delegate: StyledRect {
                    id: rectDelegate

                    required property var modelData
                    required property int index
                    property int animationDelay: root.isSessionOpen ? (4 - rectDelegate.index) * 50 : rectDelegate.index * 50
                    property real animProgress: 0
                    property bool isHighlighted: mouseArea.containsMouse || (iconDelegate.focus && rectDelegate.index === root.currentIndex)

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 70

                    color: isHighlighted ? Colours.withAlpha(Colours.m3Colors.m3Secondary, 0.2) : "transparent"

                    Component.onCompleted: {
                        rectDelegate.animProgress = 0;
                    }

                    focus: root.isSessionOpen
                    onFocusChanged: {
                        if (focus && root.isSessionOpen)
                        Qt.callLater(() => {
                                         let firstIcon = repeater.itemAt(root.currentIndex);
                                         if (firstIcon)
                                         firstIcon.children[0].forceActiveFocus();
                                     });
                    }

                    Timer {
                        id: animTimer

                        interval: rectDelegate.animationDelay
                        running: true
                        onTriggered: rectDelegate.animProgress = root.isSessionOpen ? 1 : 0
                    }

                    Connections {
                        target: root
                        function onIsSessionOpenChanged() {
                            if (root.isSessionOpen)
                                rectDelegate.animProgress = 0;

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

                    MaterialIcon {
                        id: iconDelegate

                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3Primary
                        font.pointSize: Appearance.fonts.large * 3
                        icon: rectDelegate.modelData.icon

                        Connections {
                            target: root
                            function onCurrentIndexChanged() {
                                if (root.currentIndex === rectDelegate.index)
                                    iconDelegate.forceActiveFocus();
                            }
                        }

                        Keys.onEnterPressed: handleAction()
                        Keys.onReturnPressed: handleAction()
                        Keys.onUpPressed: {
                            if (root.currentIndex > 0)
                            root.currentIndex--;
                        }
                        Keys.onDownPressed: {
                            if (root.currentIndex < 4)
                            root.currentIndex++;
                        }
                        Keys.onEscapePressed: root.isSessionOpen = false

                        scale: mouseArea.pressed ? 0.95 : 1.0

                        Behavior on scale {
                            NAnim {}
                        }

                        function handleAction() {
                            root.pendingAction = rectDelegate.modelData.action;
                            root.pendingActionName = rectDelegate.modelData.name + "?";
                            root.showConfirmDialog = true;
                        }

                        MArea {
                            id: mouseArea

                            anchors.fill: parent
                            layerColor: "transparent"
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                parent.focus = true;
                                root.currentIndex = rectDelegate.index;
                                parent.handleAction();
                            }

                            onEntered: {
                                parent.focus = true;
                                root.currentIndex = rectDelegate.index;
                            }
                        }
                    }
                }
            }
        }
    }

    DialogBox {
        id: boxConfirmation

        header: StyledText {
            text: "Session"
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideMiddle
            font.pixelSize: Appearance.fonts.extraLarge
            font.bold: true
        }
        body: StyledText {
            text: "Do you want to " + root.pendingActionName.toLowerCase() + "?"
            font.pixelSize: Appearance.fonts.large
            color: Colours.m3Colors.m3OnSurface
            wrapMode: Text.Wrap
            width: parent.width
        }
        active: root.showConfirmDialog

        onAccepted: {
            if (root.pendingAction)
            root.pendingAction();

            root.showConfirmDialog = false;
            root.isSessionOpen = false;
            root.pendingAction = null;
            root.pendingActionName = "";
        }

        onRejected: {
            root.showConfirmDialog = false;
            root.pendingAction = null;
            root.pendingActionName = "";
        }
    }
}
