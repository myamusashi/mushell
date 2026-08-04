pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base

Item {
    id: root

    anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        bottomMargin: Appearance.margin.normal
    }

    required property bool isLockscreenOpen
    required property var pam

    property string inputBuffer: ""
    property bool showErrorMessage: false

    property alias contentLayout: bar.contentLayout
    property alias lockIcon: bar.lockIcon
    property string iconName: bar.lockIcon.icon

    implicitHeight: 0

    Behavior on implicitHeight {
        NAnim {}
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: Appearance.spacing.normal

        Item {
            Layout.fillWidth: true
        }

        Bar {
            id: bar

            mediaLayout: mediaPlayer.mediaLayout
            showErrorMessage: root.showErrorMessage
        }

        MediaPlayer {
            id: mediaPlayer
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
