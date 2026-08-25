pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Components.Base
import qs.Components.Button
import "Settings"

Item {
    id: root

    anchors {
        left: parent.left
        verticalCenter: parent.verticalCenter
        leftMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize - 0.05 : 0 // no gap
    }

    property int saveIndex: 0
    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen

    implicitWidth: GlobalStates.isQuickSettingsOpen ? parent.width * 0.3 : 0
    implicitHeight: parent.height * 0.8
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.TopLeftCorner
        location2: Qt.BottomLeftCorner
        extensionSide: Qt.Vertical
        active: GlobalStates.isQuickSettingsOpen
    }

    WrapperRectangle {
        id: rect

        anchors.fill: parent
        margin: Appearance.margin.large
        topMargin: 40
        clip: true
        color: GlobalStates.drawerColors
        radius: 0
        topRightRadius: Appearance.rounding.normal
        bottomRightRadius: Appearance.rounding.normal

        ColumnLayout {
            WrapperRectangle {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                implicitWidth: Math.min(parent.width, tabGroup.implicitWidth + 32)
                implicitHeight: 56
                color: Colours.overlayColor(GlobalStates.drawerColors, Colours.m3Colors.m3SurfaceContainer, 0.5)
                margin: Appearance.margin.normal
                radius: Appearance.rounding.full

                ConnectedButtonGroup {
                    id: tabGroup

                    currentIndex: root.saveIndex

                    model: [
                        {
                            icon: "settings",
                            label: qsTr("Settings")
                        },
                        {
                            icon: "speaker",
                            label: qsTr("Volume")
                        },
                        {
                            icon: "speed",
                            label: qsTr("Performance")
                        }
                    ]

                    onClicked: index => root.saveIndex = index
                }
            }

            Item {
                id: pageContainer

                Layout.fillWidth: true
                Layout.fillHeight: true

                property int previousIndex: 0

                SettingsPage {
                    pageIndex: 0
                    currentIndex: root.saveIndex
                    content: Component {
                        Settings {}
                    }
                }

                SettingsPage {
                    pageIndex: 1
                    currentIndex: root.saveIndex
                    content: Component {
                        VolumeSettings {}
                    }
                }

                SettingsPage {
                    pageIndex: 2
                    currentIndex: root.saveIndex
                    content: Component {
                        Performances {}
                    }
                }
            }
        }
    }

    component SettingsPage: Item {
        id: animRoot

        required property int pageIndex
        required property int currentIndex
        required property Component content

        anchors.fill: parent
        opacity: currentIndex === pageIndex ? 1 : 0
        x: currentIndex === pageIndex ? 0 : currentIndex > pageIndex ? -parent.width * 0.05 : parent.width * 0.05
        enabled: currentIndex === pageIndex
        z: currentIndex === pageIndex ? 1 : 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        Loader {
            id: pageLoader

            anchors.fill: parent
            asynchronous: true
            sourceComponent: animRoot.content
            active: animRoot.currentIndex === animRoot.pageIndex

            Timer {
                id: unloadTimer

                interval: 30000
                running: !pageLoader.active
                onTriggered: {}
            }
        }
    }
}
