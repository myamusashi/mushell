pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

Scope {
    id: scope

    property bool isWallpaperSwitcherOpen: false
    property string currentWallpaper: Paths.currentWallpaper
    property var wallpaperList: []
    property string searchQuery: ""
    property string debouncedSearchQuery: ""

    Timer {
        id: searchDebounceTimer

        interval: 300
        repeat: false
        onTriggered: scope.debouncedSearchQuery = scope.searchQuery
    }

    property var filteredWallpaperList: {
        if (debouncedSearchQuery === "")
            return wallpaperList;

        const query = debouncedSearchQuery.toLowerCase();
        return wallpaperList.filter(path => {
            const fileName = path.split('/').pop().toLowerCase();
            return fileName.includes(query);
        });
    }

    Process {
        id: listWallpaper

        workingDirectory: Paths.wallpaperDir
        command: ["sh", "-c", `find -L ${Paths.wallpaperDir} -type d -path */.* -prune -o -not -name .* -type f -print`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const wallList = text.trim().split('\n').filter(path => path.length > 0);
                scope.wallpaperList = wallList;
            }
        }
    }

    OuterShapeItem {
        id: root

		content: container
		needKeyboardFocus: scope.isWallpaperSwitcherOpen

		StyledRect {
			id: container

			width: Hypr.focusedMonitor.width * 0.5
			height: scope.isWallpaperSwitcherOpen ? Hypr.focusedMonitor.height * 0.5 : 0
			color: Themes.m3Colors.m3Surface
			radius: 0
			topLeftRadius: Appearance.rounding.normal
			topRightRadius: Appearance.rounding.normal

			anchors {
				bottom: parent.bottom
				horizontalCenter: parent.horizontalCenter
			}

			Behavior on height {
				NAnim {
					duration: Appearance.animations.durations.small
				}
			}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.spacing.normal
                spacing: Appearance.spacing.normal

                StyledTextField {
                    id: searchField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: "Search wallpapers..."
                    text: scope.searchQuery
                    focus: true

                    onTextChanged: {
                        scope.searchQuery = text;
                        searchDebounceTimer.restart();

                        if (wallpaperGrid.count > 0)
                            wallpaperGrid.currentIndex = 0;
                    }

                    Keys.onDownPressed: wallpaperGrid.focus = true
                    Keys.onEscapePressed: scope.isWallpaperSwitcherOpen = false
                }

                GridView {
                    id: wallpaperGrid

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: scope.filteredWallpaperList

                    cellWidth: width / 3
                    cellHeight: height / 3

                    clip: true
                    cacheBuffer: 0

                    Component.onCompleted: {
                        const idx = scope.wallpaperList.indexOf(Paths.currentWallpaper);
                        currentIndex = idx !== -1 ? idx : 0;
                    }

                    delegate: Item {
                        id: delegateItem

                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight

                        required property var modelData
                        required property int index

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: "transparent"

                            Image {
                                anchors.fill: parent
                                source: "file://" + delegateItem.modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                cache: true

                                layer.enabled: true
                                layer.smooth: true
                            }

                            StyledLabel {
                                anchors.centerIn: parent
                                visible: wallpaperGrid.currentIndex === delegateItem.index ? false : true
                                text: delegateItem.modelData.split('/').pop()
                            }

                            StyledRect {
                                anchors.fill: parent
                                color: wallpaperGrid.currentIndex === delegateItem.index ? "transparent" : Themes.withAlpha(Themes.m3Colors.m3Surface, 0.7)
                                radius: Appearance.rounding.small
                                border.width: wallpaperGrid.currentIndex === delegateItem.index ? 3 : 1
                                border.color: wallpaperGrid.currentIndex === delegateItem.index ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OutlineVariant
                            }

                            MArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    wallpaperGrid.currentIndex = delegateItem.index;
                                    Quickshell.execDetached({
                                        command: ["sh", "-c", `shell ipc call img set ${delegateItem.modelData}`]
                                    });
                                }
                            }
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            Quickshell.execDetached({
                                command: ["sh", "-c", `shell ipc call img set ${scope.filteredWallpaperList[currentIndex]}`]
                            });
                        }
                        if (event.key === Qt.Key_Escape)
                            scope.isWallpaperSwitcherOpen = false;
                        if (event.key === Qt.Key_Tab)
                            searchField.focus = true;
                    }
                }

                StyledLabel {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Appearance.spacing.small
                    text: wallpaperGrid.count > 0 ? (wallpaperGrid.currentIndex + 1) + " / " + wallpaperGrid.count : "0 / 0"
                    color: Themes.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.small
                }
            }
        }
    }

    Timer {
        id: cleanupTimer

        interval: 500
        repeat: false
        onTriggered: {
            gc();
        }
    }
}
