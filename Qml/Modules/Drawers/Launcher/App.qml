pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Vast

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize - 0.05 : 0 // no gap
    }

    property bool isNavigating: false
    property bool isLauncherOpen: GlobalStates.isLauncherOpen
    property int currentIndex: 0

    implicitWidth: parent.width * 0.3
    implicitHeight: GlobalStates.isLauncherOpen ? parent.height * 0.5 : 0
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    function launch(entry: DesktopEntry): void {
        const cmd = entry.runInTerminal ? ["app2unit", "--", Configs.generals.apps.terminal, ...entry.command] : ["app2unit", "--", ...entry.command];

        Quickshell.execDetached({
            command: cmd,
            workingDirectory: entry.workingDirectory
        });
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.BottomLeftCorner
        location2: Qt.BottomRightCorner
        extensionSide: Qt.Horizontal
        active: GlobalStates.isLauncherOpen
        radiusActive: 40 + (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0)
    }

    WrapperRectangle {
        anchors.fill: parent
        radius: 0
        topLeftRadius: Appearance.rounding.large
        topRightRadius: Appearance.rounding.large
        color: GlobalStates.drawerColors

        Loader {
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isLauncherOpen // qmllint disable
            asynchronous: true
            sourceComponent: FocusCage {
                active: GlobalStates.isLauncherOpen
                defaultFocus: search

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.margin.large
                    spacing: Appearance.spacing.normal

                    Timer {
                        id: searchDebounce

                        interval: 80
                        repeat: false
                        onTriggered: {
                            root.isNavigating = false;
                            listView.currentIndex = listView.count > 0 ? 0 : -1;
                            listView.positionViewAtBeginning();
                        }
                    }

                    StyledTextInput {
                        id: search

                        implicitWidth: parent.width
                        implicitHeight: 60
                        placeHolderText: qsTr("Search")
                        toggleButtonVisible: false
                        onTextChanged: searchDebounce.restart()
                        Keys.onPressed: function (event) {
                            switch (event.key) {
                            case Qt.Key_Return:
                            case Qt.Key_Tab:
                            case Qt.Key_Enter:
                                if (listView.count > 0) {
                                    listView.focus = true;
                                    listView.currentItem.forceActiveFocus();
                                    event.accepted = true;
                                }
                                break;
                            case Qt.Key_Escape:
                                GlobalStates.isLauncherOpen = false;
                                event.accepted = true;
                                break;
                            case Qt.Key_Down:
                                if (listView.count > 0) {
                                    root.isNavigating = true;
                                    listView.focus = true;
                                    event.accepted = true;
                                }
                                break;
                            }
                        }
                    }

                    ListView {
                        id: listView

                        property var searchResults: SearchEngine.searchApps(DesktopEntries.applications.values, search.text)

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: ScriptModel {
                            values: listView.searchResults
                        }
                        clip: true
                        spacing: Appearance.spacing.normal
                        cacheBuffer: implicitHeight
                        highlightMoveDuration: root.isNavigating ? 200 : 0
                        maximumFlickVelocity: 1000
                        highlightMoveVelocity: -1
                        highlightFollowsCurrentItem: true
                        highlight: StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            width: listView.width
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

                            implicitWidth: listView.width
                            implicitHeight: 50
                            contentItem: RowLayout {
                                spacing: Appearance.spacing.normal

                                StyledRect {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.leftMargin: Appearance.margin.normal
                                    implicitWidth: 40
                                    implicitHeight: 40
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
                                        backer.cache: true
                                        source: Quickshell.iconPath(delegateItem.modelData.icon, "image-missing")
                                        asynchronous: true
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.rightMargin: Appearance.margin.normal
                                    spacing: 2

                                    HighlightText {
                                        Layout.fillWidth: true
                                        searchText: search.text
                                        fullText: delegateItem.modelData.name || ""
                                        font.pixelSize: Appearance.fonts.size.large
                                        elide: Text.ElideRight
                                        font.weight: Font.DemiBold
                                        color: Colours.m3Colors.m3OnSurface
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: delegateItem.modelData.comment
                                        font.pixelSize: Appearance.fonts.size.small
                                        elide: Text.ElideRight
                                        color: Colours.m3Colors.m3OnSurfaceVariant
                                    }
                                }
                            }

                            background: Item {}

                            MArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    root.launch(delegateItem.modelData);
                                    GlobalStates.isLauncherOpen = false;
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
                                    GlobalStates.isLauncherOpen = false;
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Escape:
                                    GlobalStates.isLauncherOpen = false;
                                    event.accepted = true;
                                    break;
                                }
                            }
                        }
                        StyledText {
                            anchors.centerIn: parent
                            visible: listView.count === 0 && search.text !== ""
                            text: qsTr("No applications found")
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.large
                        }
                    }
                }
            }
        }
    }
}
