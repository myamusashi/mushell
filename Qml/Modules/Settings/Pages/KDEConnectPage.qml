pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Components.Base
import qs.Components.Dialog.FileDialog
import qs.Services

import "../Components"

SettingsPageBase {
    id: page

    pageTitle: qsTr("KDE Connect")

    property string deviceIdToTransfer: ""

    SettingsCard {
        title: qsTr("Device Discovery")

        SettingRow {
            label: qsTr("Enable Polling:")
            description: qsTr("Periodically poll for KDE Connect devices on the network.")

            StyledSwitch {
                checked: Configs.kdeConnect.pollingEnabled
                onCheckedChanged: Configs.kdeConnect.pollingEnabled = checked
            }
        }

        SettingRow {
            label: qsTr("Poll Interval (s):")
            description: qsTr("How often to scan for devices, in seconds.")

            StyledTextInput {
                text: (Configs.kdeConnect.pollInterval / 1000).toString()
                onTextChanged: {
                    var parsed = parseInt(text);
                    if (!isNaN(parsed) && parsed > 0)
                        Configs.kdeConnect.pollInterval = parsed * 1000;
                }
                Layout.preferredWidth: 120
                toggleButtonVisible: false
            }
        }
    }

    SettingsCard {
        title: qsTr("Local Device")

        SettingRow {
            label: qsTr("Device ID:")
            description: qsTr("Unique identifier of this device.")

            StyledText {
                text: KDEConnect.myDeviceId || qsTr("Not detected")
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideMiddle
                Layout.maximumWidth: 300
            }
        }
    }

    SettingsCard {
        title: qsTr("Paired Devices")

        ColumnLayout {
            spacing: Appearance.spacing.normal

            Loader {
                Layout.alignment: Qt.AlignHCenter
                active: KDEConnect.allDevices.length === 0
                sourceComponent: StyledText {
                    text: qsTr("No devices paired")
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
            }

            Repeater {
                model: KDEConnect.allDevices

                delegate: RowLayout {
                    id: deviceDelegate

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    Icon {
                        icon: "smartphone"
                        font.pixelSize: Appearance.fonts.size.normal
                        color: Colours.m3Colors.m3Primary
                    }

                    ColumnLayout {
                        spacing: 2

                        StyledText {
                            text: deviceDelegate.modelData.name
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.DemiBold
                            color: Colours.m3Colors.m3OnSurface
                        }

                        StyledText {
                            text: deviceDelegate.modelData.id
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: 250
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        implicitWidth: transferLabel.implicitWidth + 24
                        implicitHeight: 32
                        radius: Appearance.rounding.small
                        color: transferMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"

                        StyledText {
                            id: transferLabel

                            anchors.centerIn: parent
                            text: qsTr("Transfer")
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.DemiBold
                            color: Colours.m3Colors.m3Primary
                        }

                        MArea {
                            id: transferMouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                page.deviceIdToTransfer = deviceDelegate.modelData.id;
                                transferFileDialog.openFileDialog();
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Available Devices")

        ColumnLayout {
            spacing: Appearance.spacing.normal

            Loader {
                Layout.alignment: Qt.AlignHCenter
                active: KDEConnect.availableDevices.length === 0
                sourceComponent: StyledText {
                    text: qsTr("No devices available")
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
            }

            Repeater {
                model: KDEConnect.availableDevices

                delegate: RowLayout {
                    id: availableDelegate

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    Icon {
                        icon: "smartphone"
                        font.pixelSize: Appearance.fonts.size.normal
                        color: Colours.m3Colors.m3Primary
                    }

                    ColumnLayout {
                        spacing: 2

                        StyledText {
                            text: availableDelegate.modelData.name
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.DemiBold
                            color: Colours.m3Colors.m3OnSurface
                        }

                        StyledText {
                            text: availableDelegate.modelData.id
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: 250
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        implicitWidth: pairLabel.implicitWidth + 24
                        implicitHeight: 32
                        radius: Appearance.rounding.small
                        color: pairMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"

                        StyledText {
                            id: pairLabel

                            anchors.centerIn: parent
                            text: qsTr("Pair")
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.DemiBold
                            color: Colours.m3Colors.m3Primary
                        }

                        MArea {
                            id: pairMouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: KDEConnect.pair(availableDelegate.modelData.id)
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: transferFileDialog

        selectFolder: false
        onFileSelected: path => {
            if (page.deviceIdToTransfer)
                KDEConnect.shareFile(page.deviceIdToTransfer, path.replace("file://", ""));
        }
    }
}
