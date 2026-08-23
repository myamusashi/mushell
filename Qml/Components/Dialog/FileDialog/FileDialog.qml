pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel
import Quickshell
import Vast.Search

import qs.Core.Configs
import qs.Core.Utils
import qs.Components.Base
import qs.Services

import "components"

LazyLoader {
    id: root

    property var nameFilters: ["*"]
    property bool showHidden: false
    property bool foldersOnly: false
    property bool selectFolder: false
    property var history: []
    property int historyIndex: -1
    property string currentFolder: "file:///home"

    property bool searchVisible: false
    property var searchedEntries: []
    property string walkedCacheKey: ""

    signal fileSelected(string path)

    function openFileDialog() {
        if (active)
            item.destroy();
        else
            activeAsync = true;
    }

    activeAsync: false
    component: FloatingWindow {
        id: window

        title: "File Dialog"
        implicitWidth: 800
        implicitHeight: 560
        minimumSize: Qt.size(600, 420)
        color: Colours.m3Colors.m3Surface
        onClosed: root.activeAsync = false

        readonly property bool searchMode: root.searchVisible && searchField.text.length > 0

        onSearchModeChanged: fileListView.clearSelection()

        TabNavigator {
            id: tabNav

            scope: mainLayout
            defaultItem: topAppBar.pathField

            Component.onCompleted: {
                Qt.callLater(() => firstFocus());
            }
        }

        Component.onCompleted: {
            var home = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
            navigateTo(home);
        }

        function navigateTo(path: string): url {
            const url = path.startsWith("file://") ? path : "file://" + path;

            clearSearch();

            // Truncate forward history
            if (root.historyIndex < root.history.length - 1)
                root.history = root.history.slice(0, root.historyIndex + 1);

            root.history.push(url);
            root.historyIndex = root.history.length - 1;
            root.currentFolder = url;
            fileListView.clearSelection();
        }

        function toggleSearch() {
            root.searchVisible = !root.searchVisible;
            if (root.searchVisible)
                searchField.forceActiveFocus();
            else
                clearSearch();
        }

        function clearSearch() {
            searchField.text = "";
            SearchEngine.clearFileResults();
        }

        function runFileSearch() {
            const query = searchField.text;
            if (!root.searchVisible || query.length === 0) {
                SearchEngine.clearFileResults();
                return;
            }

            const configuredRoots = Configs.search.fileDirs;
            const roots = configuredRoots && configuredRoots.length > 0 ? configuredRoots : [root.currentFolder.toString().replace("file://", "")];
            const cacheKey = [roots.join("|"), fileListView.folderHidden, root.nameFilters.join("|")].join("~");

            walker.roots = roots;
            walker.maxDepth = Configs.search.maxDepth;
            walker.showHidden = fileListView.folderHidden;
            walker.nameFilters = root.nameFilters;

            if (!walker.walking && (cacheKey !== root.walkedCacheKey || root.searchedEntries.length === 0)) {
                root.walkedCacheKey = cacheKey;
                walker.requestWalk();
            }

            SearchEngine.searchFilesAsync(root.searchedEntries, query);
        }

        function goBack() {
            if (root.historyIndex > 0) {
                root.historyIndex--;
                root.currentFolder = root.history[root.historyIndex];
                fileListView.clearSelection();
            }
        }

        function goForward() {
            if (root.historyIndex < root.history.length - 1) {
                root.historyIndex++;
                root.currentFolder = root.history[root.historyIndex];
                fileListView.clearSelection();
            }
        }

        function goUp() {
            if (folderModel.parentFolder)
                navigateTo(folderModel.parentFolder.toString().replace("file://", ""));
        }

        function refresh() {
            var temp = root.currentFolder;
            root.currentFolder = "file:///";
            root.currentFolder = temp;
        }

        function formatSize(bytes) {
            if (bytes < 1024)
                return bytes + " " + qsTr("B");
            if (bytes < 1048576)
                return (bytes / 1024).toFixed(1) + " " + qsTr("KiB");
            if (bytes < 1073741824)
                return (bytes / 1048576).toFixed(1) + " " + qsTr("MiB");
            return (bytes / 1073741824).toFixed(1) + " " + qsTr("GiB");
        }

        FolderListModel {
            id: folderModel

            folder: root.currentFolder
            showHidden: fileListView.folderHidden
            showDirsFirst: true
            showDotAndDotDot: false
            showFiles: !root.foldersOnly
            nameFilters: root.nameFilters

            onStatusChanged: {
                if (status === FolderListModel.Ready)
                    topAppBar.isLoading = false;
            }
        }

        DirectoryWalker {
            id: walker
        }

        Timer {
            id: searchDebounce

            interval: 200
            repeat: false
            onTriggered: window.runFileSearch()
        }

        Connections {
            target: walker

            function onWalkFinished(entries) {
                root.searchedEntries = entries;
                if (root.searchVisible && searchField.text.length > 0)
                    window.runFileSearch();
            }
        }

        ColumnLayout {
            id: mainLayout

            anchors.fill: parent
            spacing: Appearance.spacing.small

            Keys.onTabPressed: tabNav.next()
            Keys.onBacktabPressed: tabNav.previous()

            TopAppBar {
                id: topAppBar

                Layout.fillWidth: true
                canGoBack: root.historyIndex > 0
                canGoForward: root.historyIndex < root.history.length - 1
                canGoUp: root.currentFolder !== "file:///"
                currentPath: root.currentFolder.toString().replace("file://", "")

                onBackClicked: window.goBack()
                onForwardClicked: window.goForward()
                onUpClicked: window.goUp()
                onRefreshClicked: {
                    isLoading = true;
                    window.refresh();
                    root.walkedCacheKey = "";
                    if (searchField.text.length > 0)
                        window.runFileSearch();
                }
                onPathEntered: path => window.navigateTo(path)
                onSearchToggled: window.toggleSearch()
            }

            Rectangle {
                id: searchBar

                Layout.fillWidth: true
                implicitHeight: root.searchVisible ? 52 : 0
                visible: root.searchVisible
                clip: true
                color: Colours.m3Colors.m3SurfaceContainer

                Behavior on implicitHeight {
                    NAnim {}
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.margin.normal
                    anchors.rightMargin: Appearance.margin.normal

                    Icon {
                        icon: "search"
                        font.pixelSize: Appearance.fonts.size.medium
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }

                    StyledTextInput {
                        id: searchField

                        Layout.fillWidth: true
                        placeHolderText: qsTr("Search files…")
                        toggleButtonVisible: false
                        autoFocus: false

                        onTextChanged: searchDebounce.restart()
                        onKeyPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                window.toggleSearch();
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                PlacesSidebar {
                    id: placesSidebar

                    Layout.preferredWidth: 200
                    Layout.fillHeight: true
                    onPlaceSelected: path => window.navigateTo(path)
                }

                FileListView {
                    id: fileListView

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: window.searchMode ? SearchEngine.fileResults : folderModel
                    folderHidden: root.showHidden
                    selectFolder: root.selectFolder
                    onFolderDoubleClicked: path => window.navigateTo(path)
                    onFileDoubleClicked: path => root.fileSelected(path)
                    onSelectionChanged: (fileName, filePath, fileSize, fileModified, isImage) => {
                        bottomBar.setFileName(fileName);
                        previewPanel.imageFileSelected = isImage;
                        previewPanel.selectedFilePath = filePath;
                        previewPanel.fileSize = fileSize;
                        previewPanel.fileModified = fileModified;
                        previewPanel.fileName = fileName;
                    }
                }

                Rectangle {
                    id: previewPanel
                    property bool imageFileSelected: false
                    property string selectedFilePath: ""
                    property int fileSize: 0
                    property var fileModified
                    property string fileName: ""
                    Layout.preferredWidth: 200
                    Layout.fillHeight: true
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    visible: fileListView.hasSelection && !fileListView.currentIsFolder && imageFileSelected

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.margin.normal
                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: qsTr("Preview")
                            font.pixelSize: Appearance.fonts.size.normal
                            font.bold: true
                            color: Colours.m3Colors.m3OnSurface
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Image {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, implicitWidth)
                                height: Math.min(parent.height, implicitHeight)
                                source: previewPanel.visible ? "file://" + previewPanel.selectedFilePath : ""
                                sourceSize: Qt.size(400, 400)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: previewPanel.fileName
                                font.pixelSize: Appearance.fonts.size.small
                                color: Colours.m3Colors.m3OnSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: {
                                    if (previewPanel.fileSize < 1024)
                                        return previewPanel.fileSize + " B";
                                    if (previewPanel.fileSize < 1048576)
                                        return (previewPanel.fileSize / 1024).toFixed(1) + " KiB";
                                    return (previewPanel.fileSize / 1048576).toFixed(1) + " MiB";
                                }
                                font.pixelSize: Appearance.fonts.size.small
                                color: Colours.m3Colors.m3OnSurfaceVariant
                            }

                            StyledText {
                                text: Qt.formatDateTime(previewPanel.fileModified, "yyyy-MM-dd hh:mm")
                                font.pixelSize: Appearance.fonts.size.small
                                color: Colours.m3Colors.m3OnSurfaceVariant
                            }
                        }
                    }
                }
            }

            BottomActionBar {
                id: bottomBar

                Layout.fillWidth: true
                nameFilters: root.nameFilters
                selectFolder: root.selectFolder
                hasSelection: fileListView.hasSelection || fileName.length > 0
                onCancelClicked: root.activeAsync = false
                onOpenClicked: {
                    if (root.selectFolder) {
                        if (fileListView.currentIsFolder)
                            root.fileSelected(fileListView.currentFilePath);
                        else if (fileName.length > 0) {
                            var p = root.currentFolder.toString().replace("file://", "") + "/" + fileName;
                            root.fileSelected(p);
                        } else {
                            root.fileSelected(root.currentFolder.toString().replace("file://", ""));
                        }
                    } else {
                        if (fileListView.currentIsFolder)
                            window.navigateTo(fileListView.currentFilePath);
                        else if (fileListView.hasSelection && fileListView.currentFilePath !== "")
                            root.fileSelected(fileListView.currentFilePath);
                        else if (fileName.length > 0) {
                            var p = root.currentFolder.toString().replace("file://", "") + "/" + fileName;
                            root.fileSelected(p);
                        }
                    }
                }
            }
        }
    }
}
