import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Rectangle {
    id: root

    property alias title: titleText.text
    default property alias content: contentLayout.data

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + (Appearance.margin.large * 2)

    color: Colours.m3Colors.m3SurfaceContainerLow
    radius: Appearance.rounding.large

    Elevation {
        anchors.fill: parent
        z: -1
        level: 1
        radius: root.radius
    }

    Rectangle {
        id: flashBorder

        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: Colours.m3Colors.m3Primary
        border.width: 2
        opacity: 0
    }

    ColumnLayout {
        id: layout

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Appearance.margin.large
        }
        spacing: Appearance.spacing.larger

        StyledText {
            id: titleText

            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            color: Colours.m3Colors.m3Primary
            visible: text !== ""
        }

        ColumnLayout {
            id: contentLayout

            Layout.fillWidth: true
            spacing: Appearance.spacing.normal
        }
    }

    function flash() {
        flashSeq.restart();
    }

    SequentialAnimation {
        id: flashSeq

        NumberAnimation {
            target: flashBorder
            property: "opacity"
            to: 1
            duration: 150
        }

        PauseAnimation {
            duration: 900
        }

        NumberAnimation {
            target: flashBorder
            property: "opacity"
            to: 0
            duration: 450
        }
    }
}
