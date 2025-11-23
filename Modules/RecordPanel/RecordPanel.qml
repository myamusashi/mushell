pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Configs
import qs.Services
import qs.Components

import "Capture" as Cap

Scope {
    id: scope

	property bool open: false

	GlobalShortcut {
		name: "recordPanel"
		onPressed: scope.open = !scope.open
	}

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
			id: root

            required property ShellScreen modelData
            property int monitorWidth: Hypr.focusedMonitor.width
			property int monitorHeight: Hypr.focusedMonitor.height

            anchors {
                right: true
                left: true
                bottom: true
                top: true
            }
            screen: modelData
            color: Themes.withAlpha(Themes.m3Colors.m3Surface, 0.3)

            WlrLayershell.namespace: "shell:bar"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Normal
            focusable: true
            exclusiveZone: 0
            surfaceFormat.opaque: false
            visible: scope.open

            StyledRect {
                anchors.fill: parent
				anchors.margins: 15
				color: Themes.withAlpha(Themes.m3Colors.m3Surface, 0.3)
                width: childrenRect.width + 40
                height: childrenRect.height + 40
                radius: 0

                Loader {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    active: scope.open
                    asynchronous: true
                    width: root.monitorHeight / 2.5
                    sourceComponent: Cap.Capture {
						id: capture

                        condition: scope.open
                    }
                }
            }
        }
    }
}
