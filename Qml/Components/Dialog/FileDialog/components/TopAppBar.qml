pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

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
                    enabled: root.canGoBack,
                    clicked: () => root.backClicked()
                },
                {
                    icon: "arrow_forward",
                    enabled: root.canGoForward,
                    clicked: () => root.forwardClicked()
                },
                {
                    icon: "arrow_upward",
                    enabled: root.canGoUp,
                    clicked: () => root.upClicked()
                },
                {
                    icon: "refresh",
                    spinOnClick: root.isLoading,
                    clicked: () => root.refreshClicked()
                },
            ]
            delegate: IconButton {
                id: iconBtnDelegate

                required property var modelData

                FontMetrics {
                    id: iconBtnMetrics

                    font: iconBtnDelegate.font
                }

                Layout.preferredWidth: iconBtnMetrics.font.pixelSize + Appearance.spacing.large
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                icon: modelData.icon
                enabled: modelData.enabled
                isRotate: modelData.spinOnClick
                mArea.onClicked: modelData.clicked()
            }
        }

        Rectangle {
            id: textField

            Layout.fillWidth: true
            implicitHeight: 48
            radius: Appearance.rounding.small
            color: Colours.m3Colors.m3SurfaceContainerHighest

            // Active indicator line
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
                    NAnim {
                        duration: Appearance.animations.durations.small
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
                }
            }
        }
    }

    component IconButton: Icon {
        id: iconButton

        property bool isRotate: false
        property alias mArea: mArea

        property color target: mArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.08) : mArea.containsPress ? Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.1) : enabled ? Colours.m3Colors.m3OnSurfaceVariant : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
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
        font.pixelSize: Appearance.fonts.size.large * 1.2
        rotation: isRotate ? 0 : 360
        transformOrigin: Item.Center

        NAnim {
            id: cAnim
            target: iconButton
            property: "cBlend"
            from: 0.0
            to: 1.0
        }

        RotationAnimator on rotation {
            running: iconButton.isRotate
            loops: Animation.Infinite
            duration: Appearance.animations.durations.extraLarge
            easing.type: Easing.Linear
        }

        MouseArea {
            id: mArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
