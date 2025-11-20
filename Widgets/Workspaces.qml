pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Configs
import qs.Components
import qs.Helpers

RowLayout {
    id: root

    StyledRect {
        id: workspaceBar

        Layout.preferredWidth: workspaceRow.width + 20
        implicitHeight: 25
        color: workspaceMBarArea.containsPress ? Themes.withAlpha(Themes.m3Colors.m3SurfaceContainerHighest, 0.08) : workspaceMBarArea.containsMouse ? Themes.withAlpha(Themes.m3Colors.m3SurfaceContainerHighest, 0.1) : Themes.m3Colors.m3SurfaceContainer

        MArea {
            id: workspaceMBarArea

            anchors.fill: parent

            hoverEnabled: true

            cursorShape: Qt.PointingHandCursor
            onClicked: () => {
                Quickshell.execDetached({
                    command: ["sh", "-c", "hyprctl dispatch global quickshell:overview"]
                });
            }
        }

        Row {
            id: workspaceRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            Repeater {
                model: Workspaces.maxWorkspace || 1

                delegate: Item {
                    id: wsItem

                    required property int index
                    property bool focused: Hyprland.focusedMonitor?.activeWorkspace?.id === (index + 1)
                    width: workspaceText.width + iconGrid.width + 5
                    height: Math.max(workspaceText.height, iconGrid.height)

                    StyledText {
                        id: workspaceText

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: (wsItem.index + 1).toString()
                        color: {
                            if (workspaceMArea.containsMouse)
                                return Themes.withAlpha(Themes.m3Colors.m3Primary, 0.5);
                            if (wsItem.focused)
                                return Themes.m3Colors.m3Primary;
                            else
                                return Themes.m3Colors.m3OnBackground;
                        }
                        font.pixelSize: Appearance.fonts.medium * 1.3
                        font.bold: wsItem.focused
                    }

                    GridLayout {
                        id: iconGrid

                        property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(w => w.id === index + 1) ?? null
                        columns: 6
                        anchors.left: workspaceText.right
                        anchors.leftMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        columnSpacing: 2
                        rowSpacing: 2

                        Repeater {
                            model: iconGrid.workspace?.toplevels
                            delegate: IconImage {
                                required property HyprlandToplevel modelData
                                readonly property Toplevel waylandHandle: modelData?.wayland
                                source: Quickshell.iconPath(DesktopEntries.heuristicLookup(waylandHandle?.appId)?.icon, "image-missing")
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                backer.cache: true
                                backer.asynchronous: true
                            }
                        }
                    }

                    MArea {
                        id: workspaceMArea

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor
                        onClicked: Workspaces.switchWorkspace(wsItem.index + 1)
                    }
                }
            }
        }
    }
}
