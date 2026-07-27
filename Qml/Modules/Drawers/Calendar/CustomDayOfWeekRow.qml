pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property Component delegate: null
    property int firstDayOfWeek: Qt.locale().firstDayOfWeek

    readonly property real cellWidth: width / 7

    implicitHeight: 28

    Row {
        id: rowLayout
        anchors.fill: parent

        Repeater {
            model: Array.from({
                length: 7
            }, (_, i) => ({
                        shortName: Qt.locale().dayName((root.firstDayOfWeek + i) % 7, Locale.ShortFormat)
                    }))
            delegate: root.delegate
        }
    }
}
