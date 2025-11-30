import QtQuick

import qs.Widgets

Loader {
    active: true
    asynchronous: true

    sourceComponent: Mpris {
        anchors.centerIn: parent
        height: 40
        width: 40
    }
}
