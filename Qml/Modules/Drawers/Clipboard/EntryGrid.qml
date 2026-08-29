pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Vast.Clipboard

import qs.Core.Configs
import qs.Services
import qs.Components.Base

Item {
    id: root

    required property var uiState
    required property string searchText
    property alias entryList: entryList
    property alias verticalFlick: verticalFlick

    implicitHeight: entryList.height

    Flickable {
        id: verticalFlick

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: pageIndicatorRow.top
        anchors.topMargin: Appearance.margin.small
        anchors.bottomMargin: Appearance.margin.small
        contentWidth: width
        contentHeight: entryList.height
        clip: true
        flickableDirection: Flickable.VerticalFlick

        onDraggingChanged: scrollAnim.stop()
        onDragStarted: scrollAnim.stop()
        onFlickStarted: scrollAnim.stop()

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        GridView {
            id: entryList

            width: verticalFlick.width
            height: Math.max(1, Configs.clipboard.listEntries) * (64 + Appearance.spacing.small)

            readonly property int visualStart: root.uiState.visualActive ? Math.min(root.uiState.visualAnchor, currentIndex) : -1
            readonly property int visualEnd: root.uiState.visualActive ? Math.max(root.uiState.visualAnchor, currentIndex) : -1

            readonly property int visualSelectableCount: {
                let n = 0;
                for (let i = visualStart; i <= visualEnd; ++i) {
                    const t = ClipboardManager.model.typeAtRow(i);
                    if (t === "text" || t === "html")
                        ++n;
                }
                return n;
            }

            function visualSelectedIds(): var {
                const ids = [];
                const start = Math.min(root.uiState.visualAnchor, currentIndex);
                const end = Math.max(root.uiState.visualAnchor, currentIndex);
                for (let i = start; i <= end; ++i)
                    ids.push(ClipboardManager.model.idAtRow(i));
                return ids;
            }

            clip: false
            currentIndex: 0
            model: ClipboardManager.model
            flow: GridView.FlowTopToBottom
            cellWidth: width
            cellHeight: 64 + Appearance.spacing.small
            snapMode: GridView.SnapOneRow
            maximumFlickVelocity: 1000
            boundsBehavior: Flickable.StopAtBounds

            readonly property int itemsPerPage: Math.max(1, Configs.clipboard.listEntries)
            readonly property int maxVisibleCount: Math.min(count, Configs.clipboard.maxEntries)
            readonly property int totalPages: Math.max(1, Math.ceil(maxVisibleCount / itemsPerPage))
            readonly property int currentPage: Math.max(0, Math.min(totalPages - 1, Math.round(contentX / width)))

            onContentXChanged: {
                var maxContentX = Math.max(0, (totalPages - 1) * width);
                if (contentX > maxContentX) {
                    contentX = maxContentX;
                }
            }

            function ensureCurrentVisible() {
                const itemY = (currentIndex % itemsPerPage) * cellHeight;
                const viewport = verticalFlick.height;
                const currentY = verticalFlick.contentY;
                let targetY = -1;
                if (itemY < currentY)
                    targetY = itemY;
                else if (itemY + cellHeight > currentY + viewport)
                    targetY = itemY + cellHeight - viewport;
                if (targetY < 0)
                    return;
                targetY = Math.max(0, Math.min(targetY, verticalFlick.contentHeight - viewport));
                scrollAnim.stop();
                scrollAnim.to = targetY;
                scrollAnim.start();
            }

            onCurrentIndexChanged: ensureCurrentVisible()

            function moveCurrentIndexUp() {
                if (currentIndex > 0)
                    currentIndex--;
            }

            function moveCurrentIndexDown() {
                if (currentIndex < count - 1)
                    currentIndex++;
            }

            function moveCurrentIndexByPage(delta) {
                const page = currentPage;
                const newPage = page + delta;
                if (newPage < 0 || newPage >= totalPages)
                    return;

                const row = currentIndex % itemsPerPage;
                const pageStart = newPage * itemsPerPage;
                const pageEnd = Math.min(pageStart + itemsPerPage, count) - 1;

                currentIndex = Math.min(Math.max(pageStart + row, pageStart), pageEnd);
                contentX = newPage * width;
            }

            function moveCurrentIndexLeft() {
                moveCurrentIndexByPage(-1);
            }

            function moveCurrentIndexRight() {
                moveCurrentIndexByPage(1);
            }

            NAnim {
                id: scrollAnim

                target: verticalFlick
                property: "contentY"
                duration: Appearance.animations.durations.small
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            ScrollBar.horizontal: horizontalScrollBar

            highlightMoveDuration: 200
            highlightFollowsCurrentItem: true
            highlightRangeMode: GridView.ApplyRange
            highlight: StyledRect {
                color: Colours.m3Colors.m3SurfaceContainerHigh
                width: entryList.cellWidth
                height: entryList.cellHeight
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
                    properties: "x,y"
                    duration: Appearance.animations.durations.small
                }
                NAnim {
                    properties: "opacity,scale"
                    to: 1
                    duration: Appearance.animations.durations.small
                }
            }

            addDisplaced: Transition {
                NAnim {
                    properties: "opacity,scale"
                    to: 1
                    duration: Appearance.animations.durations.small
                }
            }

            displaced: Transition {
                NAnim {
                    properties: "opacity,scale"
                    to: 1
                    duration: Appearance.animations.durations.small
                }
            }

            delegate: Delegate {
                required property var modelData

                visible: index < Configs.clipboard.maxEntries
                entryId: modelData.entryId
                type: modelData.type
                preview: modelData.preview
                timestamp: modelData.timestamp
                pinned: modelData.pinned
                sourceApp: modelData.sourceApp
                fileName: modelData.fileName
                isSelected: GridView.isCurrentItem // qmllint disable
                inVisual: root.uiState.visualActive && index >= entryList.visualStart && index <= entryList.visualEnd
                width: GridView.view.cellWidth // qmllint disable
                height: 64
                onActivated: ClipboardManager.copyToClipboard(entryId)
                onPinToggled: (id, s) => ClipboardManager.pin(id, s)
                onRemoveRequested: id => ClipboardManager.remove(id)
            }
        }
    }

    StyledText {
        anchors.centerIn: verticalFlick
        visible: entryList.count === 0
        text: root.searchText.length > 0 ? qsTr("No results for ") + root.searchText : qsTr("Clipboard is empty")
        font.pixelSize: Appearance.fonts.size.medium
        color: Colours.m3Colors.m3OnSurfaceVariant
    }

    Row {
        id: pageIndicatorRow

        anchors.bottom: horizontalScrollBar.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Appearance.margin.small
        spacing: 6
        visible: entryList.totalPages > 1

        Repeater {
            model: entryList.totalPages

            delegate: Rectangle {
                required property int index

                implicitWidth: entryList.currentPage === index ? 16 : 6
                implicitHeight: 6
                radius: 3
                color: entryList.currentPage === index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OutlineVariant
                opacity: entryList.currentPage === index ? 1.0 : 0.5

                Behavior on implicitWidth {
                    NAnim {}
                }

                Behavior on opacity {
                    NAnim {}
                }
            }
        }
    }

    ScrollBar {
        id: horizontalScrollBar

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        orientation: Qt.Horizontal
        policy: ScrollBar.AsNeeded
    }
}
