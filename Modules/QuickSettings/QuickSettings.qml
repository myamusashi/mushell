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

StyledRect {
    id: root

    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen
    property int state: 0

    function toggleControlCenter(): void {
        GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen;
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

    color: Colours.m3Colors.m3Surface
    clip: true
    radius: 0
    bottomLeftRadius: Appearance.rounding.small
    bottomRightRadius: Appearance.rounding.small
    width: parent.width * 0.8
    height: isControlCenterOpen ? 400 : 0
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
        rightMargin: 60
    }

    Loader {
        anchors.fill: parent
        active: GlobalStates.isQuickSettingsOpen
        asynchronous: true
        sourceComponent: RowLayout {
            anchors.fill: parent

            TabColumn {
                id: tabBar

                state: root.state
                color: root.color
                scaleFactor: Math.min(1.0, root.width / root.width)
                visible: root.isControlCenterOpen
                Layout.fillWidth: true
                tabs: [
                    {
                        "icon": "settings",
                        "index": 0
                    },
                    {
                        "icon": "speaker",
                        "index": 1
                    },
                    {
                        "icon": "speed",
                        "index": 2
                    }
                ]
                onTabClicked: index => {
                    root.state = index;
                    controlCenterStackView.currentItem.viewIndex = index;
                }
            }

            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.5
                Layout.fillHeight: true
                spacing: 0

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
                            anchors.topMargin: 10

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

                                sourceComponent: VolumeSettings {}
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
