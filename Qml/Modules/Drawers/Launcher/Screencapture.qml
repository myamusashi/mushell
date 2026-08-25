pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Components.Button
import "History" as Hist

ClippingWrapperRectangle {
    id: root

    anchors.centerIn: parent

    property bool isScreenCapturePanelOpen: GlobalStates.isScreenCapturePanelOpen
    property int selectedIndex: 0
    property int selectedTab: 0

    readonly property real maxHeight: Hypr.focusedMonitor.height * 0.55
    onIsScreenCapturePanelOpenChanged: {
        if (isScreenCapturePanelOpen)
            ScreenCaptureHistory.reloadFiles();
    }

    border {
        color: GlobalStates.isScreenCapturePanelOpen ? Colours.m3Colors.m3Outline : "transparent"
        width: GlobalStates.isScreenCapturePanelOpen ? 2 : 0
    }
    color: GlobalStates.drawerColors
    clip: true
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable
    implicitWidth: root.selectedTab === 0 ? 300 : 340
    implicitHeight: GlobalStates.isScreenCapturePanelOpen && loader.item ? Math.min(loader.item.implicitHeight + 20, root.maxHeight) : 0 // qmllint disable
    radius: Appearance.rounding.normal

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.normal
        }
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.normal
        }
    }

    Loader {
        id: loader

        active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isScreenCapturePanelOpen // qmllint disable
        asynchronous: true
        sourceComponent: ColumnLayout {
            id: innerLayout

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Appearance.margin.normal
            }
            spacing: Appearance.spacing.small
            focus: true

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_Tab:
                    root.selectedTab = (root.selectedTab + 1) % 2;
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                    event.accepted = true;
                    break;
                case Qt.Key_Backtab:
                    root.selectedTab = (root.selectedTab - 1 + 2) % 2;
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    const maxIndex = root.selectedTab === 0 ? ScreenCapture.screenshotOptions.values.length - 1 : ScreenCaptureHistory.screenshotFiles.length - 1;
                    root.selectedIndex = Math.min(maxIndex, root.selectedIndex + 1);
                    event.accepted = true;
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    if (root.selectedTab === 0) {
                        const repeater = screenshotRepeater;
                        const item = repeater.itemAt(root.selectedIndex);
                        if (item && item.optionData.action) { // qmllint disable
                            item.optionData.action(); // qmllint disable
                            GlobalStates.isScreenCapturePanelOpen = false;
                        }
                    }
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    GlobalStates.isScreenCapturePanelOpen = false;
                    event.accepted = true;
                    break;
                }
            }

            Connections {
                target: root

                function onSelectedTabChanged() {
                    root.selectedIndex = 0;
                }
            }

            ConnectedButtonGroup {
                currentIndex: root.selectedTab
                model: [
                    {
                        icon: "capture",
                        label: qsTr("Capture")
                    },
                    {
                        icon: "history",
                        label: qsTr("History")
                    }
                ]

                onClicked: index => root.selectedTab = index
            }

            StackLayout {
                id: stackLayout

                Layout.fillWidth: true
                Layout.preferredHeight: root.selectedTab === 0 ? screenshotLayout.implicitHeight : Math.min(historyFlickable.contentHeight + 10, root.maxHeight * 0.65)
                currentIndex: root.selectedTab
                clip: true

                ColumnLayout {
                    id: screenshotLayout

                    spacing: Appearance.spacing.small

                    Repeater {
                        id: screenshotRepeater

                        model: ScreenCapture.screenshotOptions
                        delegate: CaptureItem {
                            required property var modelData
                            required property int index

                            Layout.preferredHeight: 38
                            Layout.fillWidth: true
                            optionData: modelData
                            optionIndex: index
                            isSelected: index === root.selectedIndex && root.selectedTab === 0
                            maxIndex: ScreenCapture.screenshotOptions.values.length - 1
                            onIndexModel: idx => root.selectedIndex = idx
                            onClosed: GlobalStates.isScreenCapturePanelOpen = false
                        }
                    }
                }

                ScrollView {
                    id: historyScroll

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(historyFlickable.contentHeight + 10, root.maxHeight * 0.65)
                    clip: true

                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Flickable {
                        id: historyFlickable

                        contentWidth: width
                        contentHeight: historyColumn.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Column {
                            id: historyColumn

                            width: historyFlickable.width
                            spacing: Appearance.spacing.small

                            Repeater {
                                model: ScriptModel {
                                    values: [...ScreenCaptureHistory.screenshotFiles]
                                }
                                delegate: Hist.Wrapper {}
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: ScreenCaptureHistory.screenshotFiles.length === 0
                                text: qsTr("No captures yet")
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                            }
                        }
                    }
                }
            }
        }
    }
}
