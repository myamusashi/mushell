pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Core.States
import qs.Services

LazyLoader {
    id: root

    property point startPos
    property point endPos
    property bool selecting: false

    property string mode: "single"
    property var virtualScreens: []
    property string frozenImageUrl: ""

    signal geometrySelected(string geometry)
    signal cancelled

    function open() {
        startPos = Qt.point(0, 0);
        endPos = Qt.point(0, 0);
        selecting = false;
        GlobalStates.isSelectionOpen = true;
    }

    function openCrossMonitor(frozenUrl) {
        mode = "cross-monitor";
        frozenImageUrl = frozenUrl;
        open();
    }

    function close() {
        mode = "single";
        frozenImageUrl = "";
        GlobalStates.isSelectionOpen = false;
    }

    activeAsync: GlobalStates.isSelectionOpen
    component: PanelWindow {
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        color: "transparent"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.layer: WlrLayer.Overlay

        Image {
            anchors.fill: parent
            source: root.mode === "cross-monitor" ? root.frozenImageUrl : ""
            visible: root.mode === "cross-monitor" && root.frozenImageUrl !== ""
            cache: false
            fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.m3Colors.m3Background, 0.5)
        }

        Rectangle {
            visible: root.selecting
            x: Math.min(root.startPos.x, root.endPos.x)
            y: Math.min(root.startPos.y, root.endPos.y)
            width: Math.abs(root.endPos.x - root.startPos.x)
            height: Math.abs(root.endPos.y - root.startPos.y)
            color: "transparent"
            border.color: Colours.m3Colors.m3OnSurface
            border.width: 2

Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.25)
        }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor

            onPressed: e => {
                root.startPos = Qt.point(e.x, e.y);
                root.endPos = Qt.point(e.x, e.y);
                root.selecting = true;
            }
            onPositionChanged: e => {
                if (root.selecting)
                    root.endPos = Qt.point(e.x, e.y);
            }
            onReleased: e => {
                root.selecting = false;
                root.close();

                const x = Math.min(root.startPos.x, e.x);
                const y = Math.min(root.startPos.y, e.y);
                const w = Math.abs(e.x - root.startPos.x);
                const h = Math.abs(e.y - root.startPos.y);

                if (w < 5 || h < 5) {
                    root.cancelled();
                    return;
                }
                root.geometrySelected(`${Math.round(x)},${Math.round(y)} ${Math.round(w)}x${Math.round(h)}`);
            }
        }

        Item {
            id: focusCatcher

            anchors.fill: parent
            focus: GlobalStates.isSelectionOpen

            Keys.onEscapePressed: {
                root.close();
                root.cancelled();
            }
            Component.onCompleted: forceActiveFocus()
        }
    }
}
