import QtQuick

import Quickshell
import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Services

PopupWindow {
    id: root

    property alias margins: background.margin
    property alias backgroundColor: background.color
    property alias radius: background.radius

    required property Component content

    property bool opened: false
    property int animationDuration: 200

    color: "transparent"
    implicitWidth: background.width
    implicitHeight: background.height

    function toggle() {
        background.state = background.state == "opened" ? "closed" : "opened";
    }

    WrapperRectangle {
        id: background

        color: Colours.m3Colors.m3Background

        opacity: 0
        Behavior on opacity {
            NAnim {
                duration: root.animationDuration
            }
        }

        states: State {
            name: "opened"
            when: root.opened
            PropertyChanges {
                background {
                    opacity: 1
                }
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "opened"
                ScriptAction {
                    script: root.visible = true
                }
            },
            Transition {
                from: "opened"
                to: ""
                SequentialAnimation {
                    PauseAnimation {
                        duration: root.animationDuration
                    }
                    ScriptAction {
                        script: root.visible = false
                    }
                }
            }
        ]

        Loader {
            active: root.visible
            sourceComponent: root.content
        }
    }
}
