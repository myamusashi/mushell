pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Button

import "../Base"

LazyLoader {
    id: root

    required property Component header
    required property Component body

    property bool needKeyboardFocus: true

    property int cardPaddingWidth: 60
    property int cardPaddingHeight: 40
    property int contentMinWidth: 300
    property int contentSpacing: Appearance.spacing.large

    signal accepted
    signal rejected

    activeAsync: false
    component: PanelWindow {
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        color: Qt.alpha(Colours.m3Colors.m3Background, 0.3)
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.needKeyboardFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        TabNavigator {
            id: tabNav

            scope: column

            Component.onCompleted: {
                Qt.callLater(() => tabNav.firstFocus());
            }
        }

        MArea {
            anchors.fill: parent
            onClicked: root.rejected()
            propagateComposedEvents: false
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: column.width + root.cardPaddingWidth
            implicitHeight: column.height + root.cardPaddingHeight

            radius: Appearance.rounding.large
            color: Colours.overlayColor(Colours.m3Colors.m3SurfaceTint, Colours.m3Colors.m3SurfaceContainerHigh, Configs.generals.alpha)
            border.color: Colours.m3Colors.m3Outline
            border.width: 2

            Column {
                id: column

                anchors.centerIn: parent
                width: Math.max(root.contentMinWidth, loaderHeader.item ? loaderHeader.implicitWidth : 0, loaderBody.item ? loaderBody.implicitWidth : 0, rowButtons.implicitWidth)
                anchors.margins: 20
                spacing: root.contentSpacing

                Keys.onTabPressed: tabNav.next()
                Keys.onBacktabPressed: tabNav.previous()

                Loader {
                    id: loaderHeader

                    width: parent.width
                    active: true
                    asynchronous: true
                    sourceComponent: root.header
                }

                StyledRect {
                    implicitWidth: parent.width
                    implicitHeight: 2
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
                    implicitWidth: parent.width
                    implicitHeight: 2
                    color: Colours.m3Colors.m3OutlineVariant
                }

                Row {
                    id: rowButtons

                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    ExtendedFloatingButton {
                        implicitWidth: 80
                        implicitHeight: 40
                        bgRadius: Appearance.rounding.normal
                        icon.name: "cancel"
                        icon.color: Colours.m3Colors.m3Primary
                        text: qsTr("No")
                        textColor: Colours.m3Colors.m3Primary
                        color: "transparent"
                        onClicked: root.rejected()
                    }

                    ExtendedFloatingButton {
                        implicitWidth: 80
                        implicitHeight: 40
                        icon.name: "check"
                        icon.color: Colours.m3Colors.m3Primary
                        text: qsTr("Yes")
                        textColor: Colours.m3Colors.m3Primary
                        color: "transparent"
                        onClicked: root.accepted()
                    }
                }
            }
        }
    }
}
