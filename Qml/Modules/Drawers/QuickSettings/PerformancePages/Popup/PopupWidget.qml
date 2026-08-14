pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services
import qs.Components.Base

WrapperRectangle {
    id: root

    property alias text: header.text
    property alias icon: header.icon
    required property Component content
    property bool isVisible: false
    property bool closing: false
    property real zoomOriginX: parent.width / 2
    property real zoomOriginY: parent.height / 2

    border {
        width: 1
        color: Colours.m3Colors.m3Outline
    }
    implicitWidth: parent.width * 0.8
    implicitHeight: Math.min(contentColumn.implicitHeight + Appearance.margin.small * 2, parent.height * 0.8)
    margin: Appearance.margin.small
    radius: Appearance.rounding.small
    color: Colours.m3Colors.m3SurfaceContainer
    visible: root.isVisible || root.closing
    enabled: root.isVisible
    scale: isVisible ? 1.0 : 0.5
    opacity: isVisible ? 1.0 : 0.0
    transformOrigin: Item.Center

    transform: Translate {
        x: root.isVisible ? 0 : root.zoomOriginX - root.width / 2
        y: root.isVisible ? 0 : root.zoomOriginY - root.height / 2
        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on y {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    onIsVisibleChanged: {
        if (!root.isVisible) {
            root.closing = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer

        // keep the popup visible only while the fade-out animation plays;
        // once invisible it leaves the hit-test path entirely (a visible item
        // at opacity 0 still swallows wheel/touch on the page below)
        interval: Appearance.animations.durations.expressiveDefaultSpatial + 50
        onTriggered: root.closing = false
    }

    ScrollView {
        id: scrollView

        ScrollBar.horizontal.interactive: contentColumn.implicitHeight > scrollView.implicitHeight
        ScrollBar.vertical.interactive: contentColumn.implicitWidth > scrollView.implicitWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: contentColumn

            width: scrollView.availableWidth
            spacing: 0

            Header {
                id: header

                Layout.fillWidth: true
                text: ""
                icon: ""
            }

            Loader {
                Layout.fillWidth: true
                Layout.margins: Appearance.margin.normal
                active: root.isVisible
                asynchronous: false
                sourceComponent: root.content
            }
        }
    }
}
