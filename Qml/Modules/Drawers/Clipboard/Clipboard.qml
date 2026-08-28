pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Components.Base

WrapperRectangle {
    id: root

    anchors.centerIn: parent

    signal closeRequested

    implicitWidth: ClipboardServices.uiState.listWidth + (Configs.clipboard.enablePreview ? (ClipboardServices.uiState.previewWidth + Appearance.spacing.small * 2) : 0)
    implicitHeight: GlobalStates.isClipboardOpen ? Configs.clipboard.height : 0
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable
    radius: Appearance.rounding.normal
    color: Colours.m3Colors.m3SurfaceContainerLow
    clip: true

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isClipboardOpen // qmllint disable
        asynchronous: true
        sourceComponent: FocusCage {
            active: GlobalStates.isClipboardOpen
            defaultFocus: Configs.clipboard.enableVimKeybinds ? vimFocus : content.searchField
            anchors.fill: parent

            Item {
                id: vimFocus

                width: 0
                height: 0
                Keys.onPressed: event => content.handleKey(event)
            }

            Content {
                id: content

                anchors.fill: parent
                uiState: ClipboardServices.uiState
            }
        }
    }
}
