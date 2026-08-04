import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

import "../Base"

LazyLoader {
    activeAsync: ToastService.model.count > 0
    component: PanelWindow {
        anchors.bottom: true
        margins.bottom: Appearance.margin.large // qmllint disable
        mask: Region {} // ignore mouse input
        WlrLayershell.layer: Hypr.focusedWsHasFullscreen ? WlrLayer.Background : WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        implicitWidth: 350
        implicitHeight: 300

        ListView {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            implicitWidth: parent.width
            implicitHeight: parent.height
            model: ToastService.model
            cacheBuffer: implicitHeight
            spacing: Appearance.spacing.small
            verticalLayoutDirection: ListView.BottomToTop

            add: Transition {
                NAnim {
                    property: "opacity"
                    from: 0
                    to: 1
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                    duration: Appearance.animations.durations.emphasizedDecel
                }
                NAnim {
                    property: "y"
                    from: 20
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                    duration: Appearance.animations.durations.emphasizedDecel
                }
            }
            remove: Transition {
                NAnim {
                    property: "opacity"
                    to: 0
                    easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
                    duration: Appearance.animations.durations.emphasizedAccel
                }
            }
            displaced: Transition {
                NAnim {
                    properties: "x,y"
                    duration: Appearance.animations.durations.small
                }
            }

            delegate: ToastDelegate {
                implicitWidth: ListView.view.width
            }
        }
    }

    component ToastDelegate: WrapperRectangle {
        id: root

        required property int index
        required property string description
        required property string header
        required property string icon
        required property int duration

        margin: Configs.generals.enableOuterBorder ? Appearance.margin.normal + Configs.generals.outerBorderSize : Appearance.margin.normal
        color: GlobalStates.drawerColors
        radius: Appearance.rounding.full

        RowLayout {
            id: rowLayout

            IconImage {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                implicitSize: 48
                backer.cache: true
                asynchronous: true
                source: Quickshell.iconPath(root.icon, "image-missing")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.header
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                    wrapMode: Text.Wrap
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.description
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    wrapMode: Text.Wrap
                }
            }
        }

        Timer {
            interval: root.duration
            running: true
            onTriggered: ToastService.model.remove(root.index)
        }
    }
}
