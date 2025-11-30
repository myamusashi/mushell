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
import qs.Services
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

    OuterShapeItem {
        id: launcher

        content: rectLauncher
        needKeyboardFocus: root.isLauncherOpen

        StyledRect {
            id: rectLauncher

            implicitWidth: Hypr.focusedMonitor.width * 0.3
            implicitHeight: root.isLauncherOpen ? Hypr.focusedMonitor.height * 0.5 : 0
            radius: 0
            topLeftRadius: Appearance.rounding.normal
            topRightRadius: Appearance.rounding.normal
            color: Themes.m3Colors.m3Surface

            Behavior on implicitHeight {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                StyledTextField {
                    id: search

                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    placeholderText: "  Search"
                    font.family: Appearance.fonts.familySans
                    focus: true
                    font.pixelSize: Appearance.fonts.large * 1.2
                    color: Themes.m3Colors.m3OnBackground
                    placeholderTextColor: Themes.m3Colors.m3OnSurfaceVariant

                    onTextChanged: {
                        root.currentIndex = 0;
                        listView.positionViewAtBeginning();
                    }

                    Keys.onPressed: function (event) {
                        switch (event.key) {
                        case Qt.Key_Return:
                        case Qt.Key_Tab:
                        case Qt.Key_Enter:
                            if (listView.count > 0) {
                                listView.focus = true;
                                event.accepted = true;
                            }
                            break;
                        case Qt.Key_Escape:
                            root.isLauncherOpen = false;
                            event.accepted = true;
                            break;
                        case Qt.Key_Down:
                            if (listView.count > 0) {
                                listView.focus = true;
                                event.accepted = true;
                            }
                            break;
                        }
                    }
                }

                ListView {
                    id: listView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: ScriptModel {
                        values: Fuzzy.fuzzySearch(DesktopEntries.applications.values, search.text, "name")
                    }

                    clip: true
                    spacing: 8

                    cacheBuffer: 100
                    reuseItems: true

                    highlightMoveDuration: 150
                    highlightMoveVelocity: -1

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: ItemDelegate {
                        id: delegateItem

                        required property DesktopEntry modelData
                        required property int index

                        width: listView.width
                        height: 80

                        contentItem: RowLayout {
                            spacing: Appearance.spacing.normal

                            StyledRect {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 64
                                Layout.leftMargin: Appearance.padding.normal

                                color: rectLauncher.color
                                border.width: listView.currentIndex === delegateItem.index ? 3 : 1
                                border.color: listView.currentIndex === delegateItem.index && !search.focus ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OutlineVariant

                                Behavior on border.width {
                                    NumberAnimation {
                                        duration: 100
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    width: 48
                                    height: 48
                                    source: Quickshell.iconPath(delegateItem.modelData.icon) || ""
                                    asynchronous: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.rightMargin: Appearance.padding.normal
                                spacing: 2

                                StyledLabel {
                                    Layout.fillWidth: true
                                    text: delegateItem.modelData.name || ""
                                    font.pixelSize: Appearance.fonts.large
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    color: Themes.m3Colors.m3OnSurface
                                }

                                StyledLabel {
                                    Layout.fillWidth: true
                                    text: delegateItem.modelData.comment
                                    font.pixelSize: Appearance.fonts.small
                                    elide: Text.ElideRight
                                    color: Themes.m3Colors.m3OnSurfaceVariant
                                    opacity: 0.7
                                }
                            }
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                root.launch(delegateItem.modelData);
                                root.isLauncherOpen = false;
                            }

                            onEntered: {
                                listView.currentIndex = delegateItem.index;
                            }
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
                                root.isLauncherOpen = false;
                                event.accepted = true;
                                break;
                            case Qt.Key_Escape:
                                root.isLauncherOpen = false;
                                event.accepted = true;
                                break;
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: listView.count === 0 && search.text !== ""
                        text: "No applications found"
                        color: Themes.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.large
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.isLauncherOpen = !root.isLauncherOpen;
            if (root.isLauncherOpen) {
                search.text = "";
                search.forceActiveFocus();
                listView.currentIndex = 0;
            }
        }
    }
}
