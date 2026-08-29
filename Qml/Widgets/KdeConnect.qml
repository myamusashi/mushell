pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Services

import "../Components/Base"

StyledRect {
    id: root

    // True while a drag hovers the widget and carries file URLs.
    property bool dragHover: false

    implicitWidth: kdeIcon.width + Appearance.padding.normal * 2
    implicitHeight: parent.height
    radius: Appearance.rounding.small
    color: root.dragHover ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    IconImage {
        id: kdeIcon

        anchors.centerIn: parent
        implicitSize: Appearance.fonts.size.large * 1.5
        source: Quickshell.iconPath("kdeconnect", "image-missing")
        asynchronous: true
        backer.cache: true
        opacity: KDEConnect.hasAvailableDevices ? 1.0 : 0.4

        Behavior on opacity {
            NAnim {}
        }
    }

    DropArea {
        anchors.fill: parent

        onEntered: drag => {
            root.dragHover = drag.hasUrls;
        }
        onPositionChanged: drag => {
            if (root.dragHover !== drag.hasUrls)
                root.dragHover = drag.hasUrls;
        }
        onExited: root.dragHover = false
        onDropped: drop => {
            root.dragHover = false;
            if (!drop.hasUrls)
                return;
            var incoming = [];
            for (var i = 0; i < drop.urls.length; i++)
                incoming.push(String(drop.urls[i]).replace("file://", ""));
            GlobalStates.shareFilesViaKdeConnect(incoming);
        }
    }
}
