pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Components

Scope {
    id: root

    property int currentIndex: 0
    property bool isLauncherOpen: false

    // Thx caelestia
    function launch(entry: DesktopEntry): void {
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["app2unit", "--", "foot", `${Quickshell.shellDir}/Assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: ["app2unit", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: {
            gc();
        }
    }

    LazyLoader {
        id: appLoader

        active: root.isLauncherOpen
        onActiveChanged: {
            cleanup.start();
        }

        component: PanelWindow {
            id: launcher

            property ShellScreen modelData

            anchors {
                left: true
                right: true
            }

            WlrLayershell.namespace: "shell:app"

            property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
            property int monitorWidth: monitor.width / monitor.scale
            property int monitorHeight: monitor.height / monitor.scale

            visible: root.isLauncherOpen
            focusable: true

            color: "transparent"
            screen: modelData
            exclusiveZone: 0
            implicitWidth: monitorWidth * 0.5
            implicitHeight: monitorHeight * 0.5
            margins.left: monitorWidth * 0.2
            margins.right: monitorWidth * 0.2
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            StyledRect {
                id: rectLauncher

                anchors.fill: parent
                radius: Appearance.rounding.large
                color: Themes.m3Colors.m3Surface
                border.color: Themes.m3Colors.m3Outline
                border.width: 2

                ColumnLayout {
                    anchors.fill: parent

                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    StyledTextField {
                        id: search

                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        placeholderText: "  Search"
                        font.family: Appearance.fonts.familySans
                        focus: true
                        font.pixelSize: Appearance.fonts.large * 1.2
                        color: Themes.m3Colors.m3OnBackground
                        placeholderTextColor: Themes.m3Colors.m3OnSurfaceVariant

                        background: StyledRect {
                            radius: Appearance.rounding.small
                            color: Themes.m3Colors.m3Surface
                            // border.color: Themes.m3Colors.m3OnBackground
                            // border.width: 2
                        }

                        onTextChanged: {
                            root.currentIndex = 0;
                        }

                        Keys.onPressed: function (event) {
                            switch (event.key) {
                            case Qt.Key_Return:
                            case Qt.Key_Tab:
                            case Qt.Key_Enter:
                                gridView.focus = true;
                                event.accepted = true;
                                break;
                            case Qt.Key_Escape:
                                root.isLauncherOpen = false;
                                event.accepted = true;
                                break;
                            case Qt.Key_Down:
                                gridView.focus = true;
                                event.accepted = true;
                                break;
                            }
                        }
                    }

                    GridView {
                        id: gridView

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        model: ScriptModel {
                            values: Fuzzy.fuzzySearch(DesktopEntries.applications.values, search.text, "name")
                        }

                        cellWidth: 160
                        cellHeight: 160
                        clip: true

                        delegate: ItemDelegate {
                            id: delegateItem

                            required property DesktopEntry modelData
                            required property int index

                            width: gridView.cellWidth
                            height: gridView.cellHeight

                            contentItem: ColumnLayout {
                                StyledRect {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 68
                                    Layout.preferredHeight: 68

                                    color: rectLauncher.color
                                    border.width: gridView.currentIndex === delegateItem.index ? 3 : 1
                                    border.color: gridView.currentIndex === delegateItem.index && search.focus !== true ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OutlineVariant

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 50
                                        height: 50
                                        source: Quickshell.iconPath(delegateItem.modelData.icon) || ""
                                    }
                                }

                                StyledLabel {
                                    Layout.fillWidth: true
                                    text: delegateItem.modelData.name || "a"
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }

                            MArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: root.launch(delegateItem.modelData)
                                onEntered: search.focus = true
                            }

                            Keys.onPressed: function (event) {
                                switch (event.key) {
                                case Qt.Key_Tab:
                                    search.focus = true;
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Return:
                                case Qt.Key_Enter:
                                    root.launch(delegateItem.modelData);
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Escape:
                                    root.isLauncherOpen = false;
                                    event.accepted = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.isLauncherOpen = !root.isLauncherOpen;
        }
    }
}
