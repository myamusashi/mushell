pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Components
import qs.Configs
import qs.Services

RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    readonly property var actions: [
        {
            "icon": "screenshot_frame",
            "title": "Screenshot",
            "script": "--screenshot-selection",
            "condition": true
        },
        {
            "icon": "screen_record",
            "title": "Screen record",
            "script": "--screenrecord-selection",
            "condition": true
        },
        {
            "icon": "content_paste",
            "title": "Clipboard",
            "command": ["kitty", "--class", "clipse", "-e", "clipse"],
            "condition": true
        }
    ]

    function executeAction(action) {
        if (action.script)
            Quickshell.execDetached({
                                        "command": ["sh", "-c", `${Quickshell.shellDir}/Assets/screen-capture.sh ${action.script}`]
                                    });
        else if (action.command)
            Quickshell.execDetached({
                                        "command": action.command
                                    });
    }

    Repeater {
        model: parent.actions

        delegate: StyledButton {
            id: button

            required property var modelData
            iconButton: modelData.icon
            buttonTitle: modelData.title
            buttonTextColor: Colours.m3Colors.m3OnPrimary
            onClicked: root.executeAction(modelData)
            enabled: modelData.condition
            mArea.layerColor: "transparent"
        }
    }
}
