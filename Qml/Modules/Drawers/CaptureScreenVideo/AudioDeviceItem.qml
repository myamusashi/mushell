pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    required property string audioName
    required property string audioDescription
    required property string iconName
    property bool isSelected: false

    signal select(string name)

    Layout.fillWidth: true
    Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
    color: "transparent"
    radius: Appearance.rounding.small

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.smaller
            rightMargin: Appearance.margin.smaller
        }
        spacing: Appearance.spacing.small

        Icon {
            type: Icon.Material
            icon: root.iconName
            color: root.isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        StyledText {
            id: audioDescriptionText
            text: root.audioDescription
            color: root.isSelected ? Colours.m3Colors.m3Primary : audioDeviceMouseArea.containsMouse ? Colours.m3Colors.m3OnSurface : Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            elide: Text.ElideRight
        }

        Icon {
            visible: root.isSelected
            type: Icon.Material
            icon: "check"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.normal
        }

        Item {
            Layout.fillWidth: true
        }
    }

    MArea {
        id: audioDeviceMouseArea
        cursorShape: Qt.PointingHandCursor
        implicitWidth: audioDescriptionText.contentWidth
        implicitHeight: parent.height
        hoverEnabled: true
        onClicked: root.select(root.audioName)
    }
}
