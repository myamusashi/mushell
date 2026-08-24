pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services
import qs.Components.Button

import "../../../Base"

Rectangle {
    id: root

    property alias fileName: fileNameField.text
    property bool hasSelection: false
    property bool selectFolder: false
    property real labelWidth: Math.max(fileNameMetrics.advanceWidth(fileNameLabel.text), filterMetrics.advanceWidth(filterLabelLoader.item.text)) + 10 // qmllint disable
    property var nameFilters: ["*"]

    signal cancelClicked
    signal openClicked

    implicitHeight: bottomCol.implicitHeight + (Appearance.margin.normal * 2)
    color: Colours.m3Colors.m3SurfaceContainer

    function setFileName(name) {
        fileNameField.text = name;
    }

    FontMetrics {
        id: fileNameMetrics

        font: fileNameLabel.font
    }

    FontMetrics {
        id: filterMetrics

        font: filterLabelLoader.item.font // qmllint disable
    }

    Elevation {
        anchors.fill: parent
        z: -1
        level: 1
    }

    Rectangle {
        anchors.top: parent.top
        implicitWidth: parent.width
        implicitHeight: 1
        color: Colours.m3Colors.m3OutlineVariant
        opacity: 0.4
    }

    ColumnLayout {
        id: bottomCol

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.margin.normal
        }
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                id: fileNameLabel

                text: root.selectFolder ? qsTr("Folder") : qsTr("File name")
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurfaceVariant
                Layout.preferredWidth: root.labelWidth
            }

            WrapperRectangle {
                FontMetrics {
                    id: fieldMetrics

                    font: fileNameField.font
                }
                Layout.fillWidth: true
                implicitHeight: fieldMetrics.height + 20
                margin: Appearance.margin.normal
                color: "transparent"

                Item {
                    StyledText {
                        id: fileNameField

                        font.pixelSize: Appearance.fonts.size.normal
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        color: Colours.m3Colors.m3Primary
                        implicitWidth: parent.width
                        implicitHeight: 1
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            Loader {
                id: filterLabelLoader

                Layout.preferredWidth: root.labelWidth
                active: !root.selectFolder
                sourceComponent: StyledText {
                    text: qsTr("Filter")
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
            }

            Loader {
                Layout.preferredWidth: 250
                Layout.fillHeight: true
                active: !root.selectFolder
                sourceComponent: WrapperRectangle {
                    margin: Appearance.margin.normal
                    color: "transparent"
                    radius: Appearance.rounding.small
                    border {
                        color: Colours.m3Colors.m3OutlineVariant
                        width: 2
                    }

                    StyledText {
                        text: root.nameFilters.join(", ")
                        font.pixelSize: Appearance.fonts.size.normal
                        color: Colours.m3Colors.m3OnSurface
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ExtendedFloatingButton {
                text: qsTr("Cancel")
                color: "transparent"
                onClicked: root.cancelClicked()
            }

            ExtendedFloatingButton {
                text: root.selectFolder ? qsTr("Select") : qsTr("Open")
                enabled: root.selectFolder ? true : root.hasSelection
                onClicked: root.openClicked()
            }
        }
    }
}
