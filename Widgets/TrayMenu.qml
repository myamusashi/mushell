pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Rectangle {
    id: root

    required property QsMenuOpener trayMenu

    clip: true
    color: Colours.m3Colors.m3SurfaceContainer
    radius: 20

    Behavior on trayMenu {
        SequentialAnimation {
            NAnim {
                from: 1
                property: "opacity"
                target: root
                to: 0
            }

            PropertyAction {
                property: "trayMenu"
                target: root
            }

            NAnim {
                from: 0
                property: "opacity"
                target: root
                to: 1
            }
        }
    }

    ListView {
        id: view

        anchors.fill: parent
        spacing: 3

        delegate: Rectangle {
            id: entry

            property var child: QsMenuOpener {
                menu: entry.modelData
            }
            required property QsMenuEntry modelData

            color: (modelData?.isSeparator) ? Colours.m3Colors.m3Outline : "transparent"
            height: (modelData?.isSeparator) ? 2 : 28
            radius: 20
            width: root.width

            MArea {
                layerColor: text.color
                visible: (entry.modelData?.enabled && !entry.modelData?.isSeparator) ?? true

                onClicked: {
                    if (entry.modelData.hasChildren) {
                        root.trayMenu = entry.child;
                        view.positionViewAtBeginning();
                    } else {
                        entry.modelData.triggered();
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: (entry.modelData?.buttonType == QsMenuButtonType.None) ? 10 : 2
                anchors.rightMargin: 10

                Item {
                    Layout.fillHeight: true
                    implicitWidth: this.height
                    visible: entry.modelData?.buttonType == QsMenuButtonType.CheckBox

                    MaterialIcon {
                        icon: (entry.modelData?.checkState != Qt.Checked) ? "check_box_outline_blank" : "check_box"
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3OnPrimary
                        font.pixelSize: parent.width * 0.8
                    }
                }

                Item {
                    Layout.fillHeight: true
                    implicitWidth: this.height
                    visible: entry.modelData?.buttonType == QsMenuButtonType.RadioButton

                    MaterialIcon {
                        icon: (entry.modelData?.checkState != Qt.Checked) ? "radio_button_unchecked" : "radio_button_checked"
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: parent.width * 0.8
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Text {
                        id: text

                        anchors.fill: parent
                        color: (entry.modelData?.enabled) ? Colours.m3Colors.m3OnSurface : Colours.m3Colors.m3Primary
                        font.pointSize: 11
                        text: entry.modelData?.text ?? ""
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Item {
                    Layout.fillHeight: true
                    implicitWidth: this.height
                    visible: entry.modelData?.icon ?? false

                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        fillMode: Image.PreserveAspectFit
                        source: Qt.resolvedUrl(entry.modelData?.icon) ?? ""
                    }
                }

                Item {
                    Layout.fillHeight: true
                    implicitWidth: this.height
                    visible: entry.modelData?.hasChildren ?? false

                    Text {
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3OnSurface
                        font.pointSize: 11
                        text: ""
                    }
                }
            }
        }
        model: ScriptModel {
            values: [...root.trayMenu?.children.values]
        }
    }
}
