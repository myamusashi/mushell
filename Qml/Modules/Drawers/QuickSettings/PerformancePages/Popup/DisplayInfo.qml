pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    id: root

    icon: "computer"
    text: qsTr("Display")

    readonly property var monitorModel: {
        let model = [];
        for (let name in Hypr.monitorData) {
            let monitor = Hypr.monitorData[name];
            model.push({
                header: qsTr("Monitor"),
                text: qsTr("Description"),
                value: monitor.description
            });
            model.push({
                header: "",
                text: qsTr("Resolution"),
                value: monitor.resolution
            });
            model.push({
                header: "",
                text: qsTr("Scale"),
                value: monitor.scale
            });
            model.push({
                header: "",
                text: qsTr("Refresh Rate"),
                value: monitor.refreshRate + " Hz"
            });
            model.push({
                header: "",
                text: qsTr("Color Management"),
                value: monitor.colorManagementPreset
            });
        }
        return model;
    }

    content: ColumnLayout {
        spacing: Appearance.spacing.normal

        Repeater {
            model: root.monitorModel.concat([
                {
                    text: qsTr("GPU")
                },
                {
                    header: "",
                    text: qsTr("Vulkan"),
                    value: SystemUsage.vulkanAvailable ? SystemUsage.vulkanVersion : qsTr("Not available")
                },
                {
                    header: "",
                    text: qsTr("OpenGL"),
                    value: SystemUsage.openglAvailable ? SystemUsage.openglVersion : qsTr("Not available")
                },
                {
                    header: "",
                    text: qsTr("vaAPI Driver"),
                    value: SystemUsage.vaApiDriver
                },
                {
                    header: "",
                    text: qsTr("OpenGL Renderer"),
                    value: SystemUsage.openglRenderer
                },
                {
                    header: "",
                    text: qsTr("OpenGL Vendor"),
                    value: SystemUsage.openglVendor
                }
            ])
            delegate: ColumnLayout {
                id: delegate

                required property var modelData
                required property int index

                spacing: Appearance.spacing.small
                Layout.fillWidth: true

                StyledText {
                    visible: delegate.modelData.header !== ""
                    text: delegate.modelData.header
                    color: Colours.m3Colors.m3Green
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.DemiBold
                    Layout.topMargin: delegate.modelData.header !== "" ? Appearance.spacing.small : 0
                }

                RowLayout {
                    visible: delegate.modelData.text !== ""
                    spacing: Appearance.spacing.small
                    Layout.fillWidth: true

                    StyledText {
                        text: delegate.modelData.text
                        color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.7)
                        font.pixelSize: Appearance.fonts.size.normal
                        Layout.minimumWidth: 120
                        Layout.preferredWidth: 150
                        horizontalAlignment: Text.AlignLeft
                    }

                    StyledText {
                        text: delegate.modelData.value || qsTr("N/A")
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    implicitHeight: 1
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                    visible: delegate.modelData.header === "" && delegate.index < root.monitorModel.length + 5
                }
            }
        }
    }
}
