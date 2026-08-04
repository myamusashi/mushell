pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property Item defaultFocus
    property bool active: false

    default property alias data: contentItem.data // qmllint disable

    onActiveChanged: {
        if (active)
            Qt.callLater(() => defaultFocus?.forceActiveFocus());
    }

    Component.onCompleted: {
        if (active && defaultFocus)
            defaultFocus.forceActiveFocus();
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
