pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Wayland

import qs.Configs
import qs.Helpers
import qs.Services

LazyLoader {
    id: root

    required property Component header
    required property Component body

    property bool needKeyboardFocus: false

    signal accepted
    signal rejected

    activeAsync: false

    component: PanelWindow {
        id: window

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        color: Colours.withAlpha(Colours.m3Colors.m3Background, 0.3)
        WlrLayershell.keyboardFocus: root.needKeyboardFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        MArea {
            anchors.fill: parent
            onClicked: root.rejected()
            propagateComposedEvents: false
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: column.width + 60
            implicitHeight: column.height + 40

            radius: Appearance.rounding.large
            color: Colours.m3Colors.m3Surface
            border.color: Colours.m3Colors.m3Outline
            border.width: 2

            Column {
                id: column

                anchors.centerIn: parent
                width: Math.max(300, loaderHeader.item ? loaderHeader.implicitWidth : 0, loaderBody.item ? loaderBody.implicitWidth : 0, rowButtons.implicitWidth)
                anchors.margins: 20
                spacing: Appearance.spacing.large

                Loader {
                    id: loaderHeader

                    width: parent.width
                    active: true
                    asynchronous: true
                    sourceComponent: root.header
                }

                StyledRect {
                    width: parent.width
                    height: 2
                    color: Colours.m3Colors.m3OutlineVariant
                }

                Loader {
                    id: loaderBody

                    width: parent.width
                    active: true
                    asynchronous: true
                    sourceComponent: root.body
                }

                StyledRect {
                    width: parent.width
                    height: 2
                    color: Colours.m3Colors.m3OutlineVariant
                }

                Row {
                    id: rowButtons

                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    StyledButton {
                        implicitWidth: 80
                        implicitHeight: 40
                        elideText: false
                        iconButton: "cancel"
                        buttonTitle: "No"
                        buttonColor: "transparent"
                        onClicked: root.rejected()
                    }

                    StyledButton {
                        implicitWidth: 80
                        implicitHeight: 40
                        iconButton: "check"
                        buttonTitle: "Yes"
                        buttonTextColor: Colours.m3Colors.m3OnPrimary
                        onClicked: root.accepted()
                    }
                }
            }
        }
    }
}
