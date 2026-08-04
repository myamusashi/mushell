pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property var island
    required property bool active

    readonly property int deviceCount: KDEConnect.availableDevices.length
    readonly property real rowHeight: 36
    readonly property real maxContentHeight: deviceCount * rowHeight + (deviceCount > 1 ? deviceCount - 1 : 0) * 4
    readonly property real visibleHeight: Math.min(200, maxContentHeight)

    implicitWidth: root.active ? computeActiveWidth() : 180
    implicitHeight: Math.max(44, visibleHeight + 40)

    function computeActiveWidth() {
        if (root.deviceCount === 0)
            return 220;
        var maximum = 0;
        for (var i = 0; i < root.deviceCount; i++) {
            deviceMetrics.text = KDEConnect.availableDevices[i].name;
            maximum = Math.max(maximum, deviceMetrics.width);
        }
        return Math.max(180, maximum + 104);
    }

    TextMetrics {
        id: deviceMetrics

        font.pixelSize: Appearance.fonts.size.normal
    }

    Loader {
        anchors.centerIn: parent
        active: root.active && root.deviceCount === 0
        sourceComponent: StyledText {
            text: qsTr("No devices available")
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }

    Flickable {
        id: deviceFlickable

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 4
            leftMargin: 4
            rightMargin: 12
        }

        height: root.visibleHeight
        contentWidth: width
        contentHeight: root.maxContentHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        visible: root.active

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: KDEConnect.availableDevices

                delegate: Rectangle {
                    id: deviceItem

                    required property var modelData

                    width: deviceFlickable.width
                    height: root.rowHeight
                    radius: Appearance.rounding.small
                    color: deviceMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"

                    MArea {
                        id: deviceMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.island.selectedDevice = deviceItem.modelData;
                            root.island.goToConfirmation();
                        }
                    }

                    RowLayout {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 12
                        }
                        spacing: Appearance.spacing.normal

                        Icon {
                            icon: "smartphone"
                            font.pixelSize: Appearance.fonts.size.normal
                            color: Colours.m3Colors.m3Primary
                        }

                        StyledText {
                            text: deviceItem.modelData.name
                            font.pixelSize: Appearance.fonts.size.normal
                            color: Colours.m3Colors.m3OnSurface
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 4
        }

        visible: root.active
        implicitWidth: Math.max(64, backLabel.implicitWidth + 20)
        implicitHeight: 26
        radius: Appearance.rounding.small
        color: backMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"

        StyledText {
            id: backLabel

            anchors.centerIn: parent
            text: qsTr("Back")
            font.pixelSize: Appearance.fonts.size.small
            font.weight: Font.DemiBold
            color: Colours.m3Colors.m3Primary
        }

        MArea {
            id: backMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.island.goBack()
        }
    }
}
