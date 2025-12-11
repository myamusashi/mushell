import QtQuick
import QtQuick.Layouts

import qs.Services
import qs.Widgets

RowLayout {
    Layout.alignment: Qt.AlignCenter
    spacing: 3

    Mpris {
        Layout.fillWidth: false
        Layout.preferredWidth: implicitWidth
    }

    RecordIndicator {
        Layout.fillWidth: false
        Layout.preferredWidth: implicitWidth
    }
}
