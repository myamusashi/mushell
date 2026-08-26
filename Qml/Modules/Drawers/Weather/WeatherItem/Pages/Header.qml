import QtQuick

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Row {
    id: root

    property alias icon: iconItem.icon
    property alias title: titleItem.text

    signal clicked

    width: parent.width
    spacing: Appearance.spacing.normal

    Icon {
        id: iconItem

        type: Icon.Material
        icon: ""
        font.pixelSize: Appearance.fonts.size.extraLarge
        color: Colours.m3Colors.m3OnSurface
    }

    StyledText {
        id: titleItem

        text: ""
        font.pixelSize: Appearance.fonts.size.extraLarge
        color: Colours.m3Colors.m3OnSurface
    }

    Item {
        width: parent.width - iconItem.width - titleItem.width - closeButton.width - root.spacing * 3
        height: 1
    }

    FloatingButton {
        id: closeButton

        size: "regular"
        icon.name: "close"
        icon.color: Colours.m3Colors.m3Red
        icon.size: Appearance.fonts.size.large * 1.5
        color: "transparent"

        onClicked: root.clicked()
    }
}
