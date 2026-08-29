pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property var island
    required property bool active

    readonly property int deviceCount: KDEConnect.availableDevices.length
    readonly property real rowHeight: 36
    readonly property real maxContentHeight: deviceCount * rowHeight + (deviceCount > 1 ? deviceCount - 1 : 0) * 4
    readonly property real visibleHeight: Math.min(200, maxContentHeight)

    implicitWidth: active ? computeActiveWidth() : 180
    implicitHeight: Math.max(44, visibleHeight + 40)

    function computeActiveWidth() {
        if (deviceCount === 0)
            return 250;
        var maximum = 0;
        for (var i = 0; i < deviceCount; i++) {
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
            spacing: Appearance.spacing.small

            Repeater {
                model: KDEConnect.availableDevices

                delegate: ExtendedFloatingButton {
                    required property var modelData

                    implicitWidth: deviceFlickable.width
                    height: root.rowHeight
                    icon.name: "smartphone"
                    icon.color: Colours.m3Colors.m3Primary
                    text: modelData.name
                    textColor: Colours.m3Colors.m3OnSurface
                    color: "transparent"
                    onClicked: {
                        root.island.selectedDevice = modelData;
                        root.island.goToConfirmation();
                    }
                }
            }
        }
    }

    ExtendedFloatingButton {
        id: backButton

        anchors {
            right: parent.right
            bottom: parent.bottom
            bottomMargin: Appearance.margin.small
        }
        implicitHeight: 26
        text: qsTr("Back")
        icon.name: "arrow_back_ios_new"
        icon.color: Colours.m3Colors.m3Primary
        textColor: Colours.m3Colors.m3OnSurface
        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.12)
        onClicked: root.island.goBack()
    }
}
