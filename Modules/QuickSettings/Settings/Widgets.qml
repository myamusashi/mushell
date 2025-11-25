pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Components

RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    readonly property var actions: [
        {
            "icon": "screenshot_frame",
            "title": "Screenshot",
            "script": "--screenshot-selection"
        },
        {
            "icon": "screen_record",
            "title": "Screen record",
            "script": "--screenrecord-selection"
        },
        {
            "icon": "content_paste",
            "title": "Clipboard",
            "command": ["kitty", "--class", "clipse", "-e", "clipse"]
        }
    ]

    function executeAction(action) {
        if (action.script)
            Quickshell.execDetached({
                command: ["sh", "-c", `${Quickshell.shellDir}/Assets/screen-capture.sh ${action.script}`]
            });
        else if (action.command)
            Quickshell.execDetached({
                command: action.command
            });
    }

    Repeater {
        model: parent.actions

        delegate: StyledButton {
            id: button

            required property var modelData
            iconButton: modelData.icon
            buttonTitle: modelData.title
            buttonTextColor: Themes.m3Colors.m3OnPrimary
            onClicked: root.executeAction(modelData)
            mArea.layerColor: "transparent"

            property real originalWidth: implicitWidth
            width: originalWidth

            states: State {
                name: "pressed"
                when: button.mArea.pressed
                PropertyChanges {
                    target: button
                    width: originalWidth * 1.05
                }
            }

            transitions: Transition {
                NAnim {
                    property: "width"
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
            }
        }
    }
}
