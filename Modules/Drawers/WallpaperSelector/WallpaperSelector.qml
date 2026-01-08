pragma ComponentBehavior: Bound

import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
    }

    property bool isWallpaperSwitcherOpen: GlobalStates.isWallpaperSwitcherOpen
    property string currentWallpaper: Paths.currentWallpaper
    property string searchQuery: ""
    property string debouncedSearchQuery: ""
    property var wallpaperList: []
    property var filteredWallpaperList: {
        if (debouncedSearchQuery === "")
            return wallpaperList;

        const query = debouncedSearchQuery.toLowerCase();
        return wallpaperList.filter(path => {
            const fileName = path.split('/').pop().toLowerCase();
            return fileName.includes(query);
        });
    }

    implicitWidth: parent.width * 0.6
    implicitHeight: isWallpaperSwitcherOpen ? parent.height * 0.3 : 0

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isWallpaperSwitcherOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomLeftCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isWallpaperSwitcherOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    IpcHandler {
        target: "wallpaperSwitcher"

        function open(): void {
            GlobalStates.isWallpaperSwitcherOpen = true;
        }
        function close(): void {
            GlobalStates.isWallpaperSwitcherOpen = false;
        }
        function toggle(): void {
            GlobalStates.isWallpaperSwitcherOpen = !GlobalStates.isWallpaperSwitcherOpen;
        }
    }

    GlobalShortcut {
        name: "wallpaperSwitcher"
        onPressed: GlobalStates.isWallpaperSwitcherOpen = !GlobalStates.isWallpaperSwitcherOpen
    }

    StyledRect {
        anchors.fill: parent
        color: GlobalStates.drawerColors
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        topRightRadius: Appearance.rounding.normal

        FolderListModel {
            id: wallpaperFolder

            folder: Qt.resolvedUrl(Paths.wallpaperDir)
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.gif"]
            showDirs: false
            showDotAndDotDot: false
            showHidden: false

            onCountChanged: {
                let list = [];
                for (let i = 0; i < count; i++) {
                    list.push(get(i, "filePath"));
                }
                root.wallpaperList = list;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacing.normal
            spacing: Appearance.spacing.normal

            focus: root.isWallpaperSwitcherOpen
            onFocusChanged: {
                if (root.isWallpaperSwitcherOpen)
                    searchField.forceActiveFocus();
            }

            StyledTextField {
                id: searchField

                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: "Search wallpapers..."
                text: root.searchQuery
                focus: true

                onTextChanged: {
                    root.searchQuery = text;
                    searchDebounceTimer.restart();

                    if (wallpaperPath.count > 0)
                        wallpaperPath.currentIndex = 0;
                }

                Keys.onDownPressed: wallpaperPath.focus = true
                Keys.onEscapePressed: root.isWallpaperSwitcherOpen = false
            }

            Timer {
                id: searchDebounceTimer

                interval: 300
                repeat: false
                onTriggered: root.debouncedSearchQuery = root.searchQuery
            }

            PathView {
                id: wallpaperPath

                Layout.fillWidth: true
                Layout.fillHeight: true

                model: root.filteredWallpaperList
                pathItemCount: 5
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5

                clip: true
                cacheItemCount: 7

                Component.onCompleted: {
                    const idx = root.wallpaperList.indexOf(Paths.currentWallpaper);
                    currentIndex = idx !== -1 ? idx : 0;
                }

                onModelChanged: {
                    if (root.debouncedSearchQuery === "" && currentIndex >= 0) {
                        Qt.callLater(() => {
                            if (currentIndex < count)
                                currentIndex = currentIndex;
                        });
                    }
                }

                path: Path {
                    startX: 0
                    startY: wallpaperPath.height / 2

                    PathLine {
                        x: wallpaperPath.width
                        y: wallpaperPath.height / 2
                    }
                }

                delegate: Item {
                    id: delegateItem

                    width: wallpaperPath.width / 5 - 16
                    height: wallpaperPath.height - 16

                    required property var modelData
                    required property int index

                    scale: PathView.isCurrentItem ? 1.1 : 0.85
                    z: PathView.isCurrentItem ? 100 : 1
                    opacity: PathView.isCurrentItem ? 1.0 : 0.6

                    Behavior on scale {
                        NAnim {}
                    }

                    Behavior on opacity {
                        NAnim {}
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: Appearance.rounding.normal
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: "file://" + delegateItem.modelData
                            sourceSize.width: 200
                            sourceSize.height: 200
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            cache: true
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                wallpaperPath.currentIndex = delegateItem.index;
                                Quickshell.execDetached({
                                    "command": ["sh", "-c", `shell ipc call img set ${delegateItem.modelData}`]
                                });
                            }
                        }
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        Quickshell.execDetached({
                            "command": ["sh", "-c", `shell ipc call img set ${root.filteredWallpaperList[currentIndex]}`]
                        });
                    }
                    if (event.key === Qt.Key_Escape)
                        root.isWallpaperSwitcherOpen = false;
                    if (event.key === Qt.Key_Tab)
                        searchField.focus = true;
                    if (event.key === Qt.Key_Left)
                        decrementCurrentIndex();
                    if (event.key === Qt.Key_Right)
                        incrementCurrentIndex();
                }
            }

            StyledLabel {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Appearance.spacing.small
                text: wallpaperPath.count > 0 ? (wallpaperPath.currentIndex + 1) + " / " + wallpaperPath.count : "0 / 0"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.small
            }
        }
    }
}
