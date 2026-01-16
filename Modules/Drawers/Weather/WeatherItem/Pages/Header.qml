import QtQuick

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Row {
    id: root

    property alias mouseArea: mArea
    property string icon
    property string title

    width: parent.width
    spacing: Appearance.spacing.normal

    Icon {
        id: iconItem

        type: Icon.Lucide
        icon: root.icon
        font.pixelSize: Appearance.fonts.size.extraLarge
        color: Colours.m3Colors.m3OnSurface
    }

    StyledText {
        id: titleText

        text: root.title
        font.pixelSize: Appearance.fonts.size.extraLarge
        color: Colours.m3Colors.m3OnSurface
    }

    Item {
        width: parent.width - iconItem.width - titleText.width - closeIcon.width - root.spacing * 3
        height: 1
    }

    Icon {
        id: closeIcon

        type: Icon.Material
        icon: "close"
        font.pixelSize: Appearance.fonts.size.large * 1.5
        color: Colours.m3Colors.m3Red

        MArea {
            id: mArea

            anchors.fill: parent
            layerColor: "transparent"
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
