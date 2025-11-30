import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
	id: root

	required property Item content
	property bool needKeyboardFocus: false

	color: "transparent"
	WlrLayershell.keyboardFocus: needKeyboardFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors {
        top: true
        right: true
        left: true
        bottom: true
    }

    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height
        intersection: Intersection.Xor
        Region {
            item: root.content
            intersection: Intersection.Xor
        }
	}
}
