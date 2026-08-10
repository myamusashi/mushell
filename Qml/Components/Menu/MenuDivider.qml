import QtQuick

import qs.Core.Configs
import qs.Services

Rectangle {
    id: root

    implicitHeight: 1
    width: parent ? parent.width - root.horizontalInset * 2 : 0
    x: root.horizontalInset
    color: Colours.m3Colors.m3OutlineVariant

    readonly property real horizontalInset: Appearance.margin.larger
}
