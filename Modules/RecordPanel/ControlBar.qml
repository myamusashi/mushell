import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ClippingRectangle {
    id: root

    anchors.fill: parent
    implicitWidth: content.width
    implicitHeight: content.implicitHeight

    RowLayout {
        id: content

        implicitWidth: parent.width
    }
}
