pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Data
import qs.Components

RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    readonly property var actions: [{
            "icon": "screenshot_frame",
            "title": "Screenshot",
            "script": "--screenshot-selection"
        }, {
            "icon": "screen_record",
            "title": "Screen record",
            "script": "--screenrecord-selection"
        }, {
            "icon": "content_paste",
            "title": "Clipboard",
            "command": ["kitty", "--class", "clipse", "-e", "clipse"]
        }]

    function executeAction(action) {
        if (action.script)
            Quickshell.execDetached({
                                        "command": ["sh", "-c", `${Quickshell.shellDir}/Assets/screen-capture.sh ${action.script}`]
                                    })
        else if (action.command)
            Quickshell.execDetached({
                                        "command": action.command
                                    })
    }

    Repeater {
        model: parent.actions

        delegate: StyledButton {
            required property var modelData

            iconButton: modelData.icon
            buttonTitle: modelData.title
            onClicked: root.executeAction(modelData)
        }
    }
}
