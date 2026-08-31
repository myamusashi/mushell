pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Services

import "../Components"

SettingsPageBase {
    id: root

    pageTitle: qsTr("Idle")

    property ListModel timeoutsModel: ListModel {}

    function seedFromConfig() {
        timeoutsModel.clear();
        for (const e of Configs.idle.timeouts)
            timeoutsModel.append({
                timeoutSeconds: e.timeoutMonitor ?? 60,
                timeoutCommand: e["on-timeout"] ?? "",
                resumeCommand: e["on-resume"] ?? ""
            });
    }

    function flushToConfig() {
        const arr = [];
        for (let i = 0; i < timeoutsModel.count; i++) {
            const e = timeoutsModel.get(i);
            arr.push({
                timeoutMonitor: e.timeoutSeconds,
                "on-timeout": e.timeoutCommand,
                "on-resume": e.resumeCommand
            });
        }
        Configs.idle.timeouts = arr;
    }

    Component.onCompleted: seedFromConfig()

    function addTimeout() {
        timeoutsModel.append({
            timeoutSeconds: 60,
            timeoutCommand: "notify-send 'Idle' 'Timeout reached'",
            resumeCommand: ""
        });
        flushToConfig();
    }

    function removeTimeout(i) {
        timeoutsModel.remove(i);
        flushToConfig();
    }

    SettingsCard {
        title: qsTr("Idle Management")

        SettingRow {
            label: qsTr("Enable Idle Detection:")
            description: qsTr("Enable automatic actions after periods of inactivity.")

            StyledSwitch {
                checked: Configs.idle.enabled
                onCheckedChanged: Configs.idle.enabled = checked
            }
        }
    }

    SettingsCard {
        title: qsTr("Timeouts")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.large

            Repeater {
                id: timeoutRepeater

                model: root.timeoutsModel
                delegate: Rectangle {
                    id: rootDelegate

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: content.implicitHeight + Appearance.margin.large * 2
                    color: Colours.m3Colors.m3SurfaceContainerHighest
                    radius: Appearance.rounding.normal

                    ColumnLayout {
                        id: content

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: Appearance.margin.large
                        }
                        spacing: Appearance.spacing.normal

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Timeout (seconds):")
                                font.pixelSize: Appearance.fonts.size.normal
                                color: Colours.m3Colors.m3OnSurfaceVariant
                            }

                            TextField {
                                id: timeoutField

                                Layout.preferredWidth: 80
                                text: rootDelegate.modelData.timeoutSeconds
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.bold: true
                                padding: Appearance.margin.normal
                                clip: true
                                inputMethodHints: Qt.ImhDigitsOnly
                                background: Rectangle {
                                    radius: Appearance.rounding.small
                                    color: Colours.m3Colors.m3SurfaceVariant
                                    opacity: 0.4
                                }

                                onEditingFinished: {
                                    let val = parseInt(text, 10);
                                    if (isNaN(val) || val < 1)
                                        val = 5;
                                    text = val;
                                    root.timeoutsModel.setProperty(rootDelegate.index, "timeoutSeconds", val);
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Command on Timeout:")
                                font.pixelSize: Appearance.fonts.size.normal
                                color: Colours.m3Colors.m3OnSurfaceVariant
                            }

                            TextField {
                                id: onTimeoutField

                                Layout.fillWidth: true
                                text: rootDelegate.modelData.timeoutCommand
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                padding: Appearance.margin.normal
                                clip: true

                                background: Rectangle {
                                    radius: Appearance.rounding.small
                                    color: Colours.m3Colors.m3SurfaceVariant
                                    opacity: 0.4
                                }

                                onEditingFinished: root.timeoutsModel.setProperty(rootDelegate.index, "timeoutCommand", text)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Command on Resume:")
                                font.pixelSize: Appearance.fonts.size.normal
                                color: Colours.m3Colors.m3OnSurfaceVariant
                            }

                            TextField {
                                id: onResumeField

                                Layout.fillWidth: true
                                text: rootDelegate.modelData.resumeCommand
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                padding: Appearance.margin.normal
                                clip: true

                                background: Rectangle {
                                    radius: Appearance.rounding.small
                                    color: Colours.m3Colors.m3SurfaceVariant
                                    opacity: 0.4
                                }

                                onEditingFinished: root.timeoutsModel.setProperty(rootDelegate.index, "resumeCommand", text)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            ExtendedFloatingButton {
                                text: qsTr("Apply")
                                Layout.preferredHeight: 32
                                onClicked: root.flushToConfig()
                            }

                            ExtendedFloatingButton {
                                text: qsTr("Remove")
                                Layout.preferredHeight: 32
                                onClicked: root.removeTimeout(rootDelegate.index)
                            }
                        }
                    }
                }
            }
        }
    }

    ExtendedFloatingButton {
        text: qsTr("Add Timeout")
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        outlined: true
        textColor: Colours.m3Colors.m3OnSurface
        onClicked: root.addTimeout()
    }
}
