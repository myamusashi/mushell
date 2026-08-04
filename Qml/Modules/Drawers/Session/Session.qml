pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Dialog

Item {
    id: root

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
        rightMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize - 0.05 : 0 // no gap
    }

    property alias dialog: boxConfirmation
    property int currentIndex: 0
    property bool isSessionOpen: GlobalStates.isSessionOpen
    property bool showConfirmDialog: false
    property string pendingAction: ""
    property string pendingActionName: ""

    implicitWidth: GlobalStates.isSessionOpen ? 80 : 0
    implicitHeight: parent.height * 0.5
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    function executeAction(action: string): void {
        const cmds = {
            "shutdown": ["shutdown", "now"],
            "reboot": ["systemctl", "reboot"],
            "suspend": ["systemctl", "suspend"],
            "logout": ["hyprctl", "dispatch", "hl.dsp.exit()"],
            "lockscreen": ["vastctl", "lock", "lock"]
        };
        const cmd = cmds[action];
        if (cmd)
            Quickshell.execDetached({
                command: cmd
            });
    }

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.TopRightCorner
        location2: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        active: GlobalStates.isSessionOpen
    }

    StyledRect {
        anchors.fill: parent
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        bottomLeftRadius: Appearance.rounding.normal
        color: GlobalStates.drawerColors

        Loader {
            anchors.fill: parent
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isSessionOpen // qmllint disable
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
                            "name": qsTr("Shutdown"),
                            "action": "shutdown"
                        },
                        {
                            "icon": "restart_alt",
                            "name": qsTr("Reboot"),
                            "action": "reboot"
                        },
                        {
                            "icon": "sleep",
                            "name": qsTr("Sleep"),
                            "action": "suspend"
                        },
                        {
                            "icon": "door_open",
                            "name": qsTr("Logout"),
                            "action": "logout"
                        },
                        {
                            "icon": "lock",
                            "name": qsTr("Lockscreen"),
                            "action": "lockscreen"
                        }
                    ]

                    delegate: StyledRect {
                        id: rectDelegate

                        required property var modelData
                        required property int index
                        property int animationDelay: GlobalStates.isSessionOpen ? (4 - rectDelegate.index) * 50 : rectDelegate.index * 50
                        property real animProgress: 0
                        property bool isHighlighted: mouseArea.containsMouse || (iconDelegate.focus && rectDelegate.index === root.currentIndex)

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 70
                        color: isHighlighted ? Qt.alpha(Colours.m3Colors.m3Secondary, 0.2) : "transparent"
                        focus: GlobalStates.isSessionOpen
                        onFocusChanged: {
                            if (focus && GlobalStates.isSessionOpen)
                                Qt.callLater(() => {
                                    let firstIcon = repeater.itemAt(root.currentIndex);
                                    if (firstIcon)
                                        firstIcon.children[0].forceActiveFocus();
                                });
                        }
                        transform: Translate {
                            x: (1 - rectDelegate.animProgress) * 120
                        }
                        Component.onCompleted: rectDelegate.animProgress = 0

                        Timer {
                            id: animTimer

                            interval: rectDelegate.animationDelay
                            running: true
                            onTriggered: rectDelegate.animProgress = GlobalStates.isSessionOpen ? 1 : 0
                        }

                        Behavior on animProgress {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }

                        Icon {
                            id: iconDelegate

                            anchors.centerIn: parent
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.large * 3
                            icon: rectDelegate.modelData.icon
                            scale: mouseArea.pressed ? 0.95 : 1.0

                            function handleAction() {
                                root.pendingAction = rectDelegate.modelData.action;
                                root.pendingActionName = rectDelegate.modelData.name + "?";
                                root.showConfirmDialog = true;
                                GlobalStates.isSessionOpen = false;
                            }

                            Behavior on scale {
                                NAnim {}
                            }

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
                            Keys.onEscapePressed: GlobalStates.isSessionOpen = false

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
                text: qsTr("Session")
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideMiddle
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.bold: true
            }
            body: StyledText {
                text: qsTr("Do you want to %1?").arg(root.pendingActionName.toLowerCase())
                font.pixelSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface
                wrapMode: Text.Wrap
                width: parent.width
            }
            active: root.showConfirmDialog

            onAccepted: {
                if (root.pendingAction)
                    root.executeAction(root.pendingAction);

                root.showConfirmDialog = false;
                GlobalStates.isSessionOpen = false;
                root.pendingAction = "";
                root.pendingActionName = "";
            }

            onRejected: {
                root.showConfirmDialog = false;
                root.pendingAction = "";
                root.pendingActionName = "";
            }
        }
    }
}
