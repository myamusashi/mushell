pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "Settings"

Item {
    id: root

    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen
    property int state: 0

    implicitWidth: parent.width * 0.8
    implicitHeight: isControlCenterOpen ? 450 : 0
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
    }

    function toggleControlCenter(): void {
        GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen;
    }

    Corner {
        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isQuickSettingsOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.TopRightCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isQuickSettingsOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    GlobalShortcut {
        name: "QuickSettings"
        onPressed: root.toggleControlCenter()
    }

    IpcHandler {
        target: "QuickSettings"

        function open(): void {
            GlobalStates.isQuickSettingsOpen = true;
        }
        function close(): void {
            GlobalStates.isQuickSettingsOpen = false;
        }
        function toggle(): void {
            GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen;
        }
    }

    StyledRect {
        id: rect

        anchors.fill: parent
        clip: true
        color: GlobalStates.drawerColors
        radius: 0
        bottomLeftRadius: Appearance.rounding.large
        bottomRightRadius: Appearance.rounding.large

        Loader {
            id: mainLoader

            anchors.fill: parent
            active: GlobalStates.isQuickSettingsOpen
            asynchronous: true
            sourceComponent: RowLayout {
                anchors.fill: parent

                ColumnLayout {
                    Layout.preferredWidth: parent.width * 0.5
                    Layout.fillHeight: true
                    spacing: 0

                    StyledRect {
                        id: tabBar

                        Layout.fillWidth: true
                        implicitHeight: 60
                        color: rect.color
                        radius: 0
                        visible: root.isControlCenterOpen

                        property int currentIndex: root.state
                        property var tabs: [
                            {
                                "icon": "settings",
                                "name": "Settings",
                                "index": 0
                            },
                            {
                                "icon": "speaker",
                                "name": "Volume",
                                "index": 1
                            },
                            {
                                "icon": "speed",
                                "name": "Performance",
                                "index": 2
                            }
                        ]

                        RowLayout {
                            id: tabLayout

                            anchors.centerIn: parent
                            spacing: 15
                            width: parent.width * 0.95

                            Repeater {
                                id: tabRepeater

                                model: tabBar.tabs

                                Item {
                                    id: tabItem

                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: tabBar.height

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Icon {
                                            id: tabIcon

                                            Layout.alignment: Qt.AlignHCenter
                                            icon: tabItem.modelData.icon
                                            type: Icon.Material
                                            font.pointSize: Appearance.fonts.size.large
                                            color: tabBar.currentIndex === tabItem.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnBackground
                                        }

                                        StyledText {
                                            id: tabText

                                            Layout.alignment: Qt.AlignHCenter
                                            text: tabItem.modelData.name
                                            font.pixelSize: Appearance.fonts.size.small
                                            color: tabBar.currentIndex === tabItem.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnBackground
                                        }
                                    }

                                    MArea {
                                        id: tabMArea

                                        anchors.fill: parent
                                        layerColor: Colours.m3Colors.m3Primary
                                        layerRadius: Appearance.rounding.small

                                        onClicked: {
                                            root.state = tabItem.index;
                                            tabBar.currentIndex = tabItem.index;
                                            controlCenterStackView.currentItem.viewIndex = tabItem.index;
                                        }
                                    }
                                }
                            }
                        }

                        StyledRect {
                            id: indicator

                            anchors.bottom: tabLayout.bottom
                            implicitWidth: tabRepeater.itemAt(tabBar.currentIndex) ? tabRepeater.itemAt(tabBar.currentIndex).width : 0
                            implicitHeight: 2
                            color: Colours.m3Colors.m3Primary
                            radius: Appearance.rounding.large

                            x: {
                                if (tabRepeater.itemAt(tabBar.currentIndex))
                                    return tabRepeater.itemAt(tabBar.currentIndex).x + tabLayout.x;
                                return 0;
                            }

                            Behavior on x {
                                NAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }

                            Behavior on width {
                                NAnim {
                                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                                }
                            }
                        }
                    }

                    StackView {
                        id: controlCenterStackView

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 500

                        property Component viewComponent: contentView

                        initialItem: viewComponent

                        onCurrentItemChanged: {
                            if (currentItem)
                                currentItem.viewIndex = root.state;
                        }

                        Component {
                            id: contentView

                            StyledRect {
                                id: shapeRect

                                anchors.fill: parent
                                anchors.leftMargin: 15
                                anchors.rightMargin: 15
                                anchors.topMargin: 15

                                radius: 0
                                bottomLeftRadius: Appearance.rounding.normal
                                bottomRightRadius: Appearance.rounding.normal
                                color: Colours.m3Colors.m3Background

                                property int viewIndex: 0

                                Loader {
                                    anchors.fill: parent
                                    active: parent.viewIndex === 0
                                    asynchronous: true
                                    visible: active

                                    sourceComponent: Settings {}
                                }

                                Loader {
                                    anchors.fill: parent
                                    active: parent.viewIndex === 1
                                    asynchronous: true
                                    visible: active

                                    sourceComponent: VolumeSettings {
                                        implicitWidth: 500
                                    }
                                }

                                Loader {
                                    anchors.fill: parent
                                    active: parent.viewIndex === 2
                                    asynchronous: true
                                    visible: active

                                    sourceComponent: Performances {}
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
