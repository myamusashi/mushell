pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Vast.ImageCache
import Vast.Utils

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

    property bool isWallpaperSwitcherOpen: GlobalStates.isWallpaperSwitcherOpen
    property int wallpaperType: 0
    readonly property var visibleWallpapers: WallpaperFileModels.filteredWallpaperList.filter(path => wallpaperType === 1 ? /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path) : !/\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path))

    function setWallpaper(path, colorSource) {
        Quickshell.execDetached({
            command: ["sh", "-c", `printf '%s' ${JSON.stringify(path)} > ${JSON.stringify(Paths.currentWallpaperFile)}`]
        });
        if (colorSource !== "")
            colorSourceImage.source = "file://" + colorSource;
    }

    function updateWallpaperColors(path) {
        colorSourceImage.source = "file://" + root.thumbnailPathFor(path);
    }

    function setVideoWallpaper(path, videoOutput) {
        videoOutput.grabToImage(imageResult => {
            if (!imageResult)
                return;
            const thumbnailPath = root.thumbnailPathFor(path);
            if (imageResult.saveToFile(thumbnailPath))
                root.setWallpaper(path, thumbnailPath);
        });
    }

    function thumbnailPathFor(path) {
        return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path) ? `/tmp/vast-wallpaper-${Qt.md5(path)}.png` : path;
    }

    Connections {
        target: Paths

        function onCurrentWallpaperChanged() {
            root.updateWallpaperColors(Paths.currentWallpaper);
        }
    }

    Connections {
        target: Configs.colors

        function onSchemeChanged() {
            root.updateWallpaperColors(Paths.currentWallpaper);
        }
    }

    Image {
        id: colorSourceImage

        asynchronous: true
        visible: false
        onStatusChanged: {
            if (status !== Image.Ready)
                return;
            const path = source.toString().replace(/^file:\/\//, "");
            ColorGenerator.generate(path, "dark", Configs.colors.toDarkColor, Configs.colors.scheme);
            ColorGenerator.generate(path, "light", Configs.colors.toWhiteColor, Configs.colors.scheme);
        }
    }

    implicitWidth: parent.width * 0.6
    implicitHeight: GlobalStates.isWallpaperSwitcherOpen ? parent.height * 0.3 : 0

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.BottomRightCorner
        location2: Qt.BottomLeftCorner
        extensionSide: Qt.Horizontal
        active: GlobalStates.isWallpaperSwitcherOpen
    }

    IpcHandler {
        target: "img"

        function set(path: string): void {
            if (!/\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path))
                ImageCache.preload(path, Qt.size(Screen.width, Screen.height));
            root.setWallpaper(path, /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path) ? "" : path);
        }
        function get(): string {
            return Paths.currentWallpaper;
        }
    }

    WrapperRectangle {
        anchors.fill: parent
        color: GlobalStates.drawerColors
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        topRightRadius: Appearance.rounding.normal

        Loader {
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isWallpaperSwitcherOpen // qmllint disable
            asynchronous: true
            sourceComponent: FocusCage {
                active: GlobalStates.isWallpaperSwitcherOpen
                defaultFocus: searchField

                anchors.fill: parent
                anchors.margins: Appearance.spacing.normal

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.normal

                    StyledTextInput {
                        id: searchField

                        Layout.fillWidth: true
                        implicitHeight: 40
                        placeHolderText: qsTr("Search wallpapers")
                        toggleButtonVisible: false
                        onTextChanged: {
                            WallpaperFileModels.searchQuery = text;
                            searchDebounceTimer.restart();
                            if (wallpaperPath.count > 0)
                                wallpaperPath.currentIndex = 0;
                        }
                        Component.onCompleted: text = WallpaperFileModels.searchQuery
                        Keys.onEscapePressed: GlobalStates.isWallpaperSwitcherOpen = false
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                wallpaperPath.moveCurrentIndex(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                wallpaperPath.moveCurrentIndex(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right) {
                                wallpaperPath.moveCurrentIndex(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left) {
                                wallpaperPath.moveCurrentIndex(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (wallpaperPath.count > 0) {
                                    const selectedPath = root.visibleWallpapers[wallpaperPath.currentIndex];
                                    root.setWallpaper(selectedPath, root.thumbnailPathFor(selectedPath));
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                root.wallpaperType = (root.wallpaperType + (event.key === Qt.Key_Tab ? 1 : -1) + 2) % 2;
                                Qt.callLater(() => wallpaperPath.selectCurrentWallpaper());
                                event.accepted = true;
                            }
                        }
                    }

                    Timer {
                        id: searchDebounceTimer

                        interval: 300
                        onTriggered: WallpaperFileModels.debouncedSearchQuery = searchField.text
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter

                        Repeater {
                            model: [qsTr("Static"), qsTr("Video")]

                            delegate: StyledButton {
                                id: tabButton

                                required property int index
                                required property string modelData

                                readonly property bool selected: root.wallpaperType === index

                                text: modelData
                                color: selected ? Colours.m3Colors.m3SecondaryContainer : "transparent"
                                textColor: selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                                rippleColor: Colours.m3Colors.m3OnSurfaceVariant
                                bgRadius: Appearance.rounding.full
                                leftPad: 16
                                rightPad: 16
                                topPad: 8
                                bottomPad: 8
                                onClicked: {
                                    root.wallpaperType = index;
                                    Qt.callLater(() => wallpaperPath.selectCurrentWallpaper());
                                }
                            }
                        }
                    }

                    PathView {
                        id: wallpaperPath

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Center card gets 2 "units", each side card gets 1 "unit"
                        // Total units = Configs.wallpaper.visibleWallpaper + 1 (center counts double)
                        readonly property real unitWidth: width / (Configs.wallpaper.visibleWallpaper + 1)

                        function selectCurrentWallpaper(): void {
                            const index = root.visibleWallpapers.indexOf(Paths.currentWallpaper);
                            currentIndex = index !== -1 ? index : 0;
                        }

                        function moveCurrentIndex(step: int): void {
                            if (count === 0)
                                return;
                            currentIndex = (currentIndex + step + count) % count;
                        }

                        model: ScriptModel {
                            values: root.visibleWallpapers
                        }

                        pathItemCount: Configs.wallpaper.visibleWallpaper
                        preferredHighlightBegin: 0.5
                        preferredHighlightEnd: 0.5
                        clip: true
                        cacheItemCount: Configs.wallpaper.visibleWallpaper + 2

                        Component.onCompleted: {
                            Qt.callLater(() => wallpaperPath.selectCurrentWallpaper());
                        }

                        Connections {
                            target: WallpaperFileModels
                            function onFilteredWallpaperListChanged(): void {
                                wallpaperPath.selectCurrentWallpaper();
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

                            required property var modelData
                            required property int index

                            readonly property bool isCurrent: PathView.isCurrentItem

                            onIsCurrentChanged: {
                                if (isCurrent && !/\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(delegateItem.modelData))
                                    ImageCache.preload(delegateItem.modelData, Qt.size(Screen.width, Screen.height));
                            }

                            // Center card = 2 units wide, side cards = 1 unit wide
                            implicitWidth: isCurrent ? wallpaperPath.unitWidth * 2 : wallpaperPath.unitWidth
                            implicitHeight: wallpaperPath.height

                            z: isCurrent ? 100 : 1
                            opacity: isCurrent ? 1.0 : 0.92

                            Behavior on implicitWidth {
                                NAnim {
                                    duration: Appearance.animations.durations.normal
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }

                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.normal
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }

                            ClippingRectangle {
                                id: cardRect

                                anchors.centerIn: parent

                                // Gap between cards scales with unit width so it looks proportional at any count
                                implicitWidth: parent.width - (delegateItem.isCurrent ? Math.max(20, wallpaperPath.unitWidth * 0.3) : Math.max(12, wallpaperPath.unitWidth * 0.2))
                                implicitHeight: parent.height

                                radius: delegateItem.isCurrent ? Appearance.rounding.large : 20

                                color: "transparent"

                                Behavior on implicitWidth {
                                    NAnim {
                                        duration: Appearance.animations.durations.normal
                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                    }
                                }
                                Behavior on implicitHeight {
                                    NAnim {
                                        duration: Appearance.animations.durations.normal
                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                    }
                                }
                                Behavior on radius {
                                    NAnim {
                                        duration: Appearance.animations.durations.normal
                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                    }
                                }

                                Image {
                                    anchors.fill: parent
                                    source: /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(delegateItem.modelData) ? "" : "file://" + delegateItem.modelData
                                    sourceSize: Qt.size(200, 200)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true

                                    Elevation {
                                        anchors.fill: parent
                                        z: -1
                                        level: 3
                                    }
                                }

                                MediaPlayer {
                                    id: videoThumbnailPlayer

                                    source: delegateItem.isCurrent && /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(delegateItem.modelData) ? "file://" + delegateItem.modelData : ""
                                    videoOutput: videoThumbnailOutput
                                    onMediaStatusChanged: {
                                        if (mediaStatus === MediaPlayer.LoadedMedia) {
                                            play();
                                            thumbnailTimer.restart();
                                            videoThumbnailOutput.grabToImage(imageResult => {
                                                if (!imageResult)
                                                    return;
                                                imageResult.saveToFile(root.thumbnailPathFor(delegateItem.modelData));
                                            });
                                        }
                                    }
                                }

                                Timer {
                                    id: thumbnailTimer

                                    interval: 100
                                    onTriggered: videoThumbnailPlayer.pause()
                                }

                                VideoOutput {
                                    id: videoThumbnailOutput

                                    anchors.fill: parent
                                    fillMode: VideoOutput.PreserveAspectCrop
                                    visible: delegateItem.isCurrent && videoThumbnailPlayer.source !== ""
                                }

                                Rectangle {
                                    id: dimOverlay
                                    property color target: Qt.rgba(0, 0, 0, delegateItem.isCurrent ? 0.0 : 0.22)
                                    property color cFrom
                                    property color cTo
                                    property bool cActive: false
                                    property real cBlend: 1.0
                                    onCBlendChanged: {
                                        if (!cActive)
                                            return;
                                        if (cBlend >= 1) {
                                            color = cTo;
                                            cActive = false;
                                        } else if (cBlend > 0) {
                                            color = Colours.blendColors(cFrom, cTo, cBlend);
                                        }
                                    }
                                    onTargetChanged: {
                                        cAnim.stop();
                                        cFrom = color;
                                        cTo = target;
                                        cActive = true;
                                        cBlend = 0.0;
                                        cAnim.start();
                                    }

                                    anchors.fill: parent
                                    radius: cardRect.radius

                                    NAnim {
                                        id: cAnim
                                        target: dimOverlay
                                        property: "cBlend"
                                        from: 0.0
                                        to: 1.0
                                    }
                                }

                                MArea {
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (!delegateItem.isCurrent) {
                                            wallpaperPath.currentIndex = delegateItem.index;
                                        } else {
                                            if (/\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(delegateItem.modelData))
                                                root.setVideoWallpaper(delegateItem.modelData, videoThumbnailOutput);
                                            else
                                                root.setWallpaper(delegateItem.modelData, delegateItem.modelData);
                                        }
                                    }
                                }
                            }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                GlobalStates.isWallpaperSwitcherOpen = false;
                                event.accepted = true;
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: wallpaperPath.count > 0 ? (wallpaperPath.currentIndex + 1) + " / " + wallpaperPath.count : "0 / 0"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.small
                    }
                }
            }
        }
    }
}
