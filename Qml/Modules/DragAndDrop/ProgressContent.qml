pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Feedback
import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property var island
    required property bool active

    implicitWidth: progressRowLayout.implicitWidth + 48
    implicitHeight: 44

    RowLayout {
        id: progressRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        LoadingIndicator {
            Layout.alignment: Qt.AlignLeft
            implicitWidth: 30
            implicitHeight: 30
            status: root.active
        }

        StyledText {
            text: qsTr("Sending...")
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
        }

        Item {
            Layout.fillWidth: true
        }

        ExtendedFloatingButton {
            implicitHeight: 28
            text: qsTr("Cancel")
            textColor: Colours.m3Colors.m3Error
            color: Qt.alpha(Colours.m3Colors.m3Error, 0.12)
            onClicked: root.island.cancelTransfer()
        }
    }
}
