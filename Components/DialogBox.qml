pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Helpers

Loader {
    id: root

    required property string header
    required property string body

    signal accepted
    signal rejected

    active: false
    asynchronous: true

    sourceComponent: PanelWindow {
        anchors.left: true
        anchors.right: true
        anchors.top: true
        anchors.bottom: true

        color: "#80000000"

        MArea {
            anchors.fill: parent
            onClicked: root.rejected()

            propagateComposedEvents: false
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 400

            readonly property real contentHeight: column.implicitHeight + 40
            implicitHeight: contentHeight

            radius: Appearance.rounding.large
            color: Themes.m3Colors.m3Surface
            border.color: Themes.m3Colors.m3Outline
            border.width: 2

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: 20
                spacing: Appearance.spacing.large

                StyledText {
                    text: root.header
                    color: Themes.m3Colors.m3OnSurface
                    elide: Text.ElideMiddle
                    font.pixelSize: Appearance.fonts.extraLarge
                    font.bold: true
                    Layout.fillWidth: true
                }

                StyledRect {
                    implicitHeight: 1
                    color: Themes.m3Colors.m3OutlineVariant
                    Layout.fillWidth: true
                }

                StyledText {
                    text: root.body
                    color: Themes.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.large
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                StyledRect {
                    implicitHeight: 1
                    color: Themes.m3Colors.m3OutlineVariant
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Appearance.spacing.normal

                    StyledButton {
                        iconButton: "cancel"
                        buttonTitle: "No"
                        buttonTextColor: Themes.m3Colors.m3OnBackground
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
