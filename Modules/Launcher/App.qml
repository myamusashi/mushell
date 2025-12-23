pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

StyledRect {
    id: root

    property int currentIndex: 0
    property bool isLauncherOpen: GlobalStates.isLauncherOpen

    GlobalShortcut {
        name: "appLauncher"
        onPressed: root.isLauncherOpen = !root.isLauncherOpen
    }

    IpcHandler {
        target: "appLauncher"

        function open(): void {
            GlobalStates.isLauncherOpen = true;
        }
        function close(): void {
            GlobalStates.isLauncherOpen = false;
        }
        function toggle(): void {
            GlobalStates.isLauncherOpen = !GlobalStates.isLauncherOpen;
        }
    }

    Component.onCompleted: {
        Fuzzy.loadLaunchHistory();
    }

    visible: window.modelData.name === Hypr.focusedMonitor.name

    // Thx caelestia
    function launch(entry: DesktopEntry): void {
        Fuzzy.updateLaunchHistory(entry);

        entry.runInTerminal ? Quickshell.execDetached({
            "command": ["app2unit", "--", Configs.generals.apps.terminal, `${Quickshell.shellDir}/Assets/wrap_term_launch.sh`, ...entry.command],
            "workingDirectory": entry.workingDirectory
        }) : Quickshell.execDetached({
            "command": ["app2unit", "--", ...entry.command],
            "workingDirectory": entry.workingDirectory
        });
    }

    radius: 0
    topLeftRadius: Appearance.rounding.normal
    topRightRadius: Appearance.rounding.normal
    color: Colours.m3Colors.m3Surface
    implicitWidth: parent.width * 0.3
    implicitHeight: isLauncherOpen ? parent.height * 0.5 : 0
    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
    }
    Loader {
        anchors.fill: parent
        active: window.modelData.name === Hypr.focusedMonitor.name && root.isLauncherOpen
        asynchronous: true

        sourceComponent: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            StyledTextField {
                id: search

                Layout.fillWidth: true
                Layout.preferredHeight: 60
				placeholderText: "  Search"
				focus: root.isPrototypeOf
				onFocusChanged: forceActiveFocus()
                font.family: Appearance.fonts.family.sans
                font.pixelSize: Appearance.fonts.size.large * 1.2
                color: Colours.m3Colors.m3OnBackground
                placeholderTextColor: Colours.m3Colors.m3OnSurfaceVariant
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
                    values: Fuzzy.fuzzySearch(DesktopEntries.applications.values // get all apps list
                    , search.text // get input fields
                    , "name" // keyword
                    , 0.55 // threshold
                    , Fuzzy.getRecencyScore // receny score
                    )
                }
                clip: true
                spacing: 8
                cacheBuffer: 100
                reuseItems: false
                preferredHighlightBegin: 0
                preferredHighlightEnd: height
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: 150
                maximumFlickVelocity: 3000
                highlightMoveVelocity: -1
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                rebound: Transition {
                    NAnim {
                        properties: "x,y"
                    }
                }

                add: Transition {
                    NAnim {
                        properties: "opacity,scale"
                        from: 0
                        to: 1
                    }
                }

                remove: Transition {
                    NAnim {
                        properties: "opacity,scale"
                        from: 1
                        to: 0
                    }
                }

                move: Transition {
                    NAnim {
                        property: "y"
                    }
                    NAnim {
                        properties: "opacity,scale"
                        to: 1
                    }
                }

                addDisplaced: Transition {
                    NAnim {
                        property: "y"
                        duration: Appearance.animations.durations.small
                    }
                    NAnim {
                        properties: "opacity,scale"
                        to: 1
                    }
                }

                displaced: Transition {
                    NAnim {
                        property: "y"
                    }
                    NAnim {
                        properties: "opacity,scale"
                        to: 1
                    }
                }

                delegate: ItemDelegate {
                    id: delegateItem

                    required property DesktopEntry modelData
                    required property int index
                    width: listView.width
                    height: 50
                    contentItem: RowLayout {
                        spacing: Appearance.spacing.normal
                        StyledRect {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.leftMargin: Appearance.padding.normal
                            clip: true
                            Behavior on border.width {
                                NAnim {}
                            }
                            Behavior on border.color {
                                CAnim {}
                            }
                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: parent.height
                                source: Quickshell.iconPath(delegateItem.modelData.icon, "image-missing")
                                asynchronous: true
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.rightMargin: Appearance.padding.normal
                            spacing: 2
                            HighlightText {
                                Layout.fillWidth: true
                                searchText: search.text
                                fullText: delegateItem.modelData.name || ""
                                font.pixelSize: Appearance.fonts.size.normal
								elide: Text.ElideRight
								font.weight: Font.DemiBold
								color: Colours.m3Colors.m3OnSurface
                                normalColor: Colours.m3Colors.m3OnSurface
                                highlightColor: Colours.m3Colors.m3Primary
                            }
                            StyledLabel {
                                Layout.fillWidth: true
                                text: delegateItem.modelData.comment
                                font.pixelSize: Appearance.fonts.size.small
                                elide: Text.ElideRight
                                color: Colours.m3Colors.m3OnSurfaceVariant
                            }
                        }
                    }

                    background: StyledRect {
                        anchors.fill: parent
                        color: listView.currentIndex === delegateItem.index ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
                    }

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.launch(delegateItem.modelData);
                            root.isLauncherOpen = false;
                        }
                        onEntered: listView.currentIndex = delegateItem.index
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
                StyledLabel {
                    anchors.centerIn: parent
                    visible: listView.count === 0 && search.text !== ""
                    text: "No applications found"
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                }
            }
        }
    }
}
