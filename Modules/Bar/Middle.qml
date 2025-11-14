import QtQuick
import QtQuick.Layouts
import qs.Widgets

Loader {
    active: true
    asynchronous: true

    sourceComponent: RowLayout {
        Layout.alignment: Qt.AlignCenter

        Mpris {
            Layout.alignment: Qt.AlignCenter
        }
    }
}
