pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Data
import qs.Helpers

Loader {
    id: root

    required property string header
    required property string body
    signal accepted
    signal rejected

    active: false

    sourceComponent: PanelWindow {
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "transparent"

        MArea {
            anchors.fill: parent
            onClicked: root.rejected()
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 400
            implicitHeight: bodyText.implicitHeight + 150
            radius: Appearance.rounding.large
            color: Themes.colors.surface
            border.color: Themes.colors.outline
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20

                StyledText {
                    id: headerText

                    text: root.header
                    color: Themes.colors.on_surface
                    elide: Qt.ElideMiddle
                    font.pixelSize: Appearance.fonts.extraLarge
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitHeight: 1
                    implicitWidth: parent.width
                    color: Themes.colors.outline_variant
                }

                StyledText {
                    id: bodyText

                    text: root.body
                    color: Themes.colors.on_background
                    font.pixelSize: Appearance.fonts.large
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Rectangle {
                    implicitHeight: 1
                    implicitWidth: parent.width
                    color: Themes.colors.outline_variant
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    spacing: 10

                    StyledButton {
                        iconButton: "cancel"
                        buttonTitle: "No"
                        buttonTextColor: Themes.colors.on_background
                        buttonColor: "transparent"
                        onClicked: root.rejected()
                    }

                    StyledButton {
                        iconButton: "check"
                        buttonTitle: "Yes"
                        onClicked: root.accepted()
                    }
                }
            }
        }
    }
}
