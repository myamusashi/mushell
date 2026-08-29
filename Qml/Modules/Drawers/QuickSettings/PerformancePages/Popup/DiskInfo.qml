pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Utils

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    id: diskInfo

    icon: "storage"
    text: qsTr("Storage")
    content: ColumnLayout {
        RowLayout {
            StyledText {
                text: SystemUsage.diskProp.toFixed(0) + qsTr(" GB used")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
            }

            StyledText {
                text: (SystemUsage.diskTotal / 1048576).toFixed(0) + qsTr(" GB total")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
            }
        }

        Slider3Values {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            freeValue: SystemUsage.storageFree / 1048576
            systemValue: SystemUsage.storageSystem / 1048576
            appsValue: SystemUsage.storageAppsData / 1048576
        }

        Repeater {
            model: [
                {
                    color: Colours.m3Colors.m3Green,
                    text: qsTr("Root"),
                    value: SystemUsage.formatKB(SystemUsage.storageAppsData)
                },
                {
                    color: Qt.alpha(Colours.m3Colors.m3Green, 0.7),
                    text: qsTr("Boot"),
                    value: SystemUsage.formatKB(SystemUsage.storageSystem)
                },
                {
                    color: Qt.alpha(Colours.m3Colors.m3Green, 0.3),
                    text: qsTr("Free"),
                    value: SystemUsage.formatKB(SystemUsage.storageFree)
                }
            ]
            delegate: RowLayout {
                required property var modelData

                StyledRect {
                    color: parent.modelData.color
                    implicitWidth: 15
                    implicitHeight: 15
                }

                StyledText {
                    text: parent.modelData.text
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: parent.modelData.value
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }
            }
        }

        StyledText {
            text: qsTr("Internal storage")
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
        }

        Repeater {
            model: filesystemModel
            delegate: ColumnLayout {
                id: delegate

                required property var modelData
                readonly property string filesystem: modelData.filesystem
                readonly property string filesystemType: modelData.filesystemType
                readonly property string mountPoint: modelData.mountPoint
                readonly property string totalMountPointData: modelData.totalMountPointData
                readonly property string totalUsed: modelData.totalUsed
                readonly property string freeSize: modelData.freeSize
                readonly property real usedValue: modelData.usedValue
                readonly property real totalValue: modelData.totalValue

                RowLayout {
                    StyledText {
                        visible: delegate.filesystem !== ""
                        text: delegate.filesystem + ": "
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: delegate.filesystemType !== ""
                        text: delegate.filesystemType
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.preferredHeight: 10
                    }
                }

                RowLayout {
                    StyledText {
                        visible: delegate.mountPoint !== "" || delegate.mountPoint !== ""
                        text: delegate.mountPoint
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: delegate.totalMountPointData !== "" || delegate.totalMountPointData !== ""
                        text: delegate.totalMountPointData
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                RowLayout {
                    StyledText {
                        visible: delegate.totalUsed !== "" || delegate.totalUsed !== ""
                        text: delegate.totalUsed
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: delegate.freeSize !== "" || delegate.freeSize !== ""
                        text: delegate.freeSize
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Slider2Values {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    visible: delegate.usedValue > 0 || delegate.totalValue > 0
                    usedValue: delegate.usedValue / 1048576
                    totalValue: delegate.totalValue / 1048576
                }
            }
        }
    }

    ListModel {
        id: filesystemModel
    }

    function syncFilesystems() {
        const list = SystemUsage.filesystemNames;

        for (let i = filesystemModel.count - 1; i >= 0; i--) {
            if (!list.some(entry => entry.name === filesystemModel.get(i).filesystem))
                filesystemModel.remove(i, 1);
        }

        for (let i = 0; i < list.length; i++) {
            const entry = list[i];
            const row = {
                filesystem: entry.name,
                filesystemType: entry.type,
                mountPoint: entry.mountpoint,
                totalMountPointData: SystemUsage.formatKB(entry.totalKB),
                totalUsed: SystemUsage.formatKB(entry.usedKB),
                freeSize: SystemUsage.formatKB(entry.freeKB),
                usedValue: entry.usedKB / 1024 / 1024,
                totalValue: entry.totalKB / 1024 / 1024
            };
            let index = -1;
            for (let j = 0; j < filesystemModel.count; j++) {
                if (filesystemModel.get(j).filesystem === entry.name) {
                    index = j;
                    break;
                }
            }
            if (index >= 0)
                filesystemModel.set(index, row);
            else
                filesystemModel.append(row);
        }
    }

    Connections {
        target: SystemUsage

        function onFilesystemNamesChanged() {
            diskInfo.syncFilesystems();
        }
    }

    Component.onCompleted: syncFilesystems()

    component Slider3Values: Item {
        id: root

        readonly property real total: freeValue + systemValue + appsValue
        readonly property real systemRatio: total > 0 ? systemValue / total : 0
        readonly property real appsRatio: total > 0 ? appsValue / total : 0
        readonly property real systemPlusAppsRatio: total > 0 ? (systemValue + appsValue) / total : 0
        property real freeValue: 0
        property real systemValue: 0
        property real appsValue: 0

        implicitHeight: 12

        StyledRect {
            anchors.fill: parent
            radius: height / 2
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
        }

        StyledRect {
            id: systemAppsBar
            property color colorFrom
            property color colorTo
            property bool colorBlending: false
            property real colorBlendProgress: 1.0

            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }

            NumberAnimation {
                id: systemAppsColorAnim
                target: systemAppsBar
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
            }

            property color target: Qt.alpha(Colours.m3Colors.m3Green, 0.5)
            onTargetChanged: {
                systemAppsColorAnim.stop();
                colorFrom = systemAppsBar.color;
                colorTo = target;
                colorBlending = true;
                colorBlendProgress = 0.0;
                systemAppsColorAnim.start();
            }

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * root.systemPlusAppsRatio
            radius: height / 2
            z: 1

            Behavior on width {
                SpringAnimation {
                    spring: 2
                    damping: 0.5
                }
            }
        }

        StyledRect {
            id: appsBar
            property color colorFrom
            property color colorTo
            property bool colorBlending: false
            property real colorBlendProgress: 1.0

            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }

            NumberAnimation {
                id: appsColorAnim
                target: appsBar
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
            }

            property color target: Colours.m3Colors.m3Green
            onTargetChanged: {
                appsColorAnim.stop();
                colorFrom = appsBar.color;
                colorTo = target;
                colorBlending = true;
                colorBlendProgress = 0.0;
                appsColorAnim.start();
            }

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * root.appsRatio
            radius: height / 2
            z: 2

            Behavior on width {
                SpringAnimation {
                    spring: 2
                    damping: 0.5
                }
            }
        }
    }

    component Slider2Values: Item {
        id: root

        readonly property real usedPercent: totalValue > 0 ? (usedValue / totalValue) : 0
        readonly property real freePercent: 1 - usedPercent

        property real usedValue: 0
        property real totalValue: 100

        implicitHeight: 12

        StyledRect {
            anchors.fill: parent
            radius: height / 2
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
        }

        StyledRect {
            id: usedBar
            property color colorFrom
            property color colorTo
            property bool colorBlending: false
            property real colorBlendProgress: 1.0

            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }

            NumberAnimation {
                id: usedBarColorAnim
                target: usedBar
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
            }

            property color target: Colours.m3Colors.m3Green
            onTargetChanged: {
                usedBarColorAnim.stop();
                colorFrom = usedBar.color;
                colorTo = target;
                colorBlending = true;
                colorBlendProgress = 0.0;
                usedBarColorAnim.start();
            }

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            implicitWidth: parent.width * root.usedPercent
            radius: height / 2

            Behavior on implicitWidth {
                SpringAnimation {
                    spring: 2
                    damping: 0.5
                }
            }
        }
    }
}
