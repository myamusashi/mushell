import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

LazyLoader {
    id: capsLockOsdLoader

    active: false
    component: PanelWindow {
        anchors.bottom: true
        WlrLayershell.namespace: "shell:osd:capslock"
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: false
        implicitWidth: 350
        implicitHeight: 50
        exclusiveZone: 0
        margins.bottom: 90
        mask: Region {}

        StyledRect {
            anchors.fill: parent
            radius: height / 2
            color: Themes.m3Colors.background

            Row {
                anchors.centerIn: parent
                spacing: 10

                StyledText {
                    text: "Caps Lock"
                    font.weight: Font.Medium
                    color: Themes.m3Colors.onBackground
                    font.pixelSize: Appearance.fonts.large * 1.5
                }

                MaterialIcon {
                    icon: KeyLockState.state.capsLock ? "lock" : "lock_open_right"
                    color: KeyLockState.state.capsLock ? Themes.m3Colors.primary : Themes.m3Colors.tertiary
                    font.pointSize: Appearance.fonts.large * 1.5
                }
            }
        }
    }
}
