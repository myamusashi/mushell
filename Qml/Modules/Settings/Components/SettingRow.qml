pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

RowLayout {
    id: root

    property alias label: label.text
    property alias description: description.text
    default property alias content: controlContainer.data

    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        StyledText {
            id: label

            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignLeft
            Layout.fillWidth: true
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            id: description

            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignLeft
            Layout.fillWidth: true
            font.pixelSize: Appearance.fonts.size.small
            color: Colours.m3Colors.m3OnSecondary
            visible: text !== ""
        }
    }

    RowLayout {
        id: controlContainer

        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        spacing: Appearance.spacing.small
    }
}
