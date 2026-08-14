pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

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
            values1: SystemUsage.storageFree / 1048576
            values2: SystemUsage.storageSystem / 1048576
            values3: SystemUsage.storageAppsData / 1048576
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
            model: fsModel
            delegate: ColumnLayout {
                id: delegate

                required property var modelData
                readonly property string fs: modelData.fs
                readonly property string fsType: modelData.fsType
                readonly property string mountPoint: modelData.mountPoint
                readonly property string totalMountPointData: modelData.totalMountPointData
                readonly property string totalUsed: modelData.totalUsed
                readonly property string freeSize: modelData.freeSize
                readonly property real values1: modelData.values1
                readonly property real values2: modelData.values2

                RowLayout {
                    StyledText {
                        visible: delegate.fs !== "" || delegate.fs !== ""
                        text: delegate.fs + ": "
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: delegate.fsType !== "" || delegate.fsType !== ""
                        text: delegate.fsType
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
                    visible: delegate.values1 > 0 || delegate.values2 > 0
                    usedValue: delegate.values1 / 1048576
                    totalValue: delegate.values2 / 1048576
                }
            }
        }
    }

    ListModel {
        id: fsModel
    }

    function syncFsList() {
        const list = SystemUsage.filesystemNames;

        for (let i = fsModel.count - 1; i >= 0; i--) {
            if (!list.some(e => e.name === fsModel.get(i).fs))
                fsModel.remove(i, 1);
        }

        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            const row = {
                fs: e.name,
                fsType: e.type,
                mountPoint: e.mountpoint,
                totalMountPointData: e.totalFormatted,
                totalUsed: e.usedFormatted,
                freeSize: e.freeFormatted,
                values1: e.usedKB / 1024 / 1024,
                values2: e.totalKB / 1024 / 1024
            };
            let index = -1;
            for (let j = 0; j < fsModel.count; j++) {
                if (fsModel.get(j).fs === e.name) {
                    index = j;
                    break;
                }
            }
            if (index >= 0)
                fsModel.set(index, row);
            else
                fsModel.append(row);
        }
    }

    Connections {
        target: SystemUsage

        function onFilesystemNamesChanged() {
            diskInfo.syncFsList();
        }
    }

    Component.onCompleted: syncFsList()

    component Slider3Values: Item {
        id: root

        readonly property real total: values1 + values2 + values3
        readonly property real systemRatio: total > 0 ? values2 / total : 0
        readonly property real appsRatio: total > 0 ? values3 / total : 0
        readonly property real systemPlusAppsRatio: total > 0 ? (values2 + values3) / total : 0
        property real values1: 0
        property real values2: 0
        property real values3: 0

        implicitHeight: 12

        StyledRect {
            anchors.fill: parent
            radius: height / 2
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
        }

        StyledRect {
            id: systemAppsBar
            property color c0From
            property color c0To
            property bool c0Active: false
            property real c0Blend: 1.0

            onC0BlendChanged: {
                if (!c0Active)
                    return;
                if (c0Blend >= 1) {
                    color = c0To;
                    c0Active = false;
                } else if (c0Blend > 0) {
                    color = Colours.blendColors(c0From, c0To, c0Blend);
                }
            }

            NumberAnimation {
                id: c0Anim
                target: systemAppsBar
                property: "c0Blend"
                from: 0.0
                to: 1.0
            }

            property color target: Qt.alpha(Colours.m3Colors.m3Green, 0.5)
            onTargetChanged: {
                c0Anim.stop();
                c0From = systemAppsBar.color;
                c0To = target;
                c0Active = true;
                c0Blend = 0.0;
                c0Anim.start();
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
            property color c1From
            property color c1To
            property bool c1Active: false
            property real c1Blend: 1.0

            onC1BlendChanged: {
                if (!c1Active)
                    return;
                if (c1Blend >= 1) {
                    color = c1To;
                    c1Active = false;
                } else if (c1Blend > 0) {
                    color = Colours.blendColors(c1From, c1To, c1Blend);
                }
            }

            NumberAnimation {
                id: c1Anim
                target: appsBar
                property: "c1Blend"
                from: 0.0
                to: 1.0
            }

            property color target: Colours.m3Colors.m3Green
            onTargetChanged: {
                c1Anim.stop();
                c1From = appsBar.color;
                c1To = target;
                c1Active = true;
                c1Blend = 0.0;
                c1Anim.start();
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
            property color c2From
            property color c2To
            property bool c2Active: false
            property real c2Blend: 1.0

            onC2BlendChanged: {
                if (!c2Active)
                    return;
                if (c2Blend >= 1) {
                    color = c2To;
                    c2Active = false;
                } else if (c2Blend > 0) {
                    color = Colours.blendColors(c2From, c2To, c2Blend);
                }
            }

            NumberAnimation {
                id: c2Anim
                target: usedBar
                property: "c2Blend"
                from: 0.0
                to: 1.0
            }

            property color target: Colours.m3Colors.m3Green
            onTargetChanged: {
                c2Anim.stop();
                c2From = usedBar.color;
                c2To = target;
                c2Active = true;
                c2Blend = 0.0;
                c2Anim.start();
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
