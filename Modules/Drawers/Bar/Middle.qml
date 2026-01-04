import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Widgets

RowLayout {
    anchors.centerIn: parent
    spacing: Appearance.spacing.normal

    Mpris {}
    RecordIndicator {}
}
