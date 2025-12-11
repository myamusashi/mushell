pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import "Settings"
ColumnLayout {
    id: root

    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen
    property int state: 0

    function toggleControlCenter(): void {
        isControlCenterOpen = !isControlCenterOpen;
    }

    GlobalShortcut {
        name: "ControlCenter"
        onPressed: root.toggleControlCenter()
    }

    width: parent.width * 0.3
    height: isControlCenterOpen ? contentHeight : 0
    spacing: 0

    property real contentHeight: tabBar.implicitHeight + divider.implicitHeight + 500

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.small
            easing.type: Easing.OutCubic
        }
    }

    anchors {
        top: parent.top
        right: parent.right
        rightMargin: 60
    }

    clip: true

    TabRow {
        id: tabBar

        state: root.state
        scaleFactor: Math.min(1.0, root.width / root.width)
        visible: root.isControlCenterOpen
        Layout.fillWidth: true
        tabs: [
            {
                "title": "Settings",
                "icon": "settings",
                "index": 0
            },
            {
                "title": "Volumes",
                "icon": "speaker",
                "index": 1
            },
            {
                "title": "Performance",
                "icon": "speed",
                "index": 2
            },
            {
                "title": "Weather",
                "icon": "cloud",
                "index": 3
            }
        ]
        onTabClicked: index => {
            root.state = index;
            controlCenterStackView.currentItem.viewIndex = index;
        }
    }

    StyledRect {
        id: divider

        Layout.fillWidth: true
        implicitHeight: root.isControlCenterOpen ? 1 : 0
        visible: root.isControlCenterOpen
        color: Colours.m3Colors.m3OutlineVariant

        Behavior on implicitHeight {
            NAnim {
                duration: Appearance.animations.durations.small
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

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 3
                    asynchronous: true
                    visible: active

                    sourceComponent: Weathers {}
                }
            }
        }
    }
}
