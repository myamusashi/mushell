pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Button

import "../../../Base"

Rectangle {
    id: root

    property bool canGoBack: false
    property bool canGoForward: false
    property bool canGoUp: false
    property bool isLoading: false
    property string currentPath: ""

    signal backClicked
    signal forwardClicked
    signal upClicked
    signal refreshClicked
    signal pathEntered(string path)
    signal showHiddenToggled
    signal searchToggled

    property alias pathField: input

    implicitHeight: 64
    color: Colours.m3Colors.m3SurfaceContainer

    Elevation {
        anchors.fill: parent
        z: -1
        level: 3
    }

    Rectangle {
        anchors.bottom: parent.bottom
        implicitWidth: parent.width
        implicitHeight: 1
        color: Colours.m3Colors.m3OutlineVariant
        opacity: 0.4
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.normal
        anchors.rightMargin: Appearance.margin.normal
        spacing: 0

        Repeater {
            model: [
                {
                    icon: "arrow_back",
                    clicked: () => root.backClicked()
                },
                {
                    icon: "arrow_forward",
                    clicked: () => root.forwardClicked()
                },
                {
                    icon: "arrow_upward",
                    clicked: () => root.upClicked()
                },
                {
                    icon: "refresh",
                    clicked: () => root.refreshClicked()
                },
                {
                    icon: "search",
                    clicked: () => root.searchToggled()
                }
            ]

            delegate: FloatingButton {
                id: iconBtnDelegate

                required property int index
                required property var modelData

                Layout.preferredWidth: Appearance.fonts.size.large * 1.2 + Appearance.spacing.large
                Layout.preferredHeight: Appearance.fonts.size.large * 1.2 + Appearance.spacing.large
                backgroundRadius: Appearance.rounding.full
                icon.name: modelData.icon
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.size: Appearance.fonts.size.large * 1.2
                color: "transparent"
                spinning: index === 3 && root.isLoading
                enabled: index === 0 ? root.canGoBack : index === 1 ? root.canGoForward : index === 2 ? root.canGoUp : true

                onClicked: modelData.clicked()
            }
        }

        Rectangle {
            id: textField

            Layout.fillWidth: true
            implicitHeight: 48
            radius: Appearance.rounding.small
            color: Colours.m3Colors.m3SurfaceContainerHighest

            Rectangle {
                id: activeIndicatorLine

                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                implicitWidth: parent.width - 4
                implicitHeight: 1
                color: Colours.m3Colors.m3OnSurfaceVariant

                states: [
                    State {
                        name: "activeFocus"
                        when: input.activeFocus
                        // qmllint disable
                        PropertyChanges {
                            target: activeIndicatorLine
                            implicitWidth: parent.width
                            implicitHeight: 2
                            color: Colours.m3Colors.m3Primary
                        }
                        // qmllint enable
                    }
                ]

                transitions: Transition {
                    ParallelAnimation {
                        NAnim {
                            properties: "implicitWidth,implicitHeight"
                            duration: Appearance.animations.durations.small
                        }
                        CAnim {
                            property: "color"
                            duration: Appearance.animations.durations.small
                        }
                    }
                }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.margin.larger
                    rightMargin: Appearance.margin.smaller
                }
                spacing: Appearance.spacing.small

                Icon {
                    icon: "folder_open"
                    font.pixelSize: Appearance.fonts.size.medium
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: root.currentPath
                    onAccepted: root.pathEntered(text)

                    property bool keyboardFocusable: true

                    function requestKeyboardFocus() {
                        input.forceActiveFocus();
                    }
                }
            }
        }
    }
}
