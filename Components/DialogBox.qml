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
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        color: Themes.withAlpha(Themes.m3Colors.m3Background, 0.3)

        MArea {
            anchors.fill: parent
            onClicked: root.rejected()
            propagateComposedEvents: false
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: column.implicitWidth + 40
            implicitHeight: column.implicitHeight + 40

            radius: Appearance.rounding.large
            color: Themes.m3Colors.m3Surface
            border.color: Themes.m3Colors.m3Outline
            border.width: 2

            Column {
                id: column

				anchors.centerIn: parent
				width: 360
                anchors.margins: 20
                spacing: Appearance.spacing.large

                StyledText {
                    text: root.header
                    color: Themes.m3Colors.m3OnSurface
                    elide: Text.ElideMiddle
                    font.pixelSize: Appearance.fonts.extraLarge
                    font.bold: true
                }

                StyledRect {
                    width: parent.width
                    height: 2
                    color: Themes.m3Colors.m3OutlineVariant
                }

                StyledText {
                    width: parent.width
                    text: root.body
                    color: Themes.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.large
                    wrapMode: Text.Wrap
                }

                StyledRect {
                    width: parent.width
                    height: 2
                    color: Themes.m3Colors.m3OutlineVariant
                }

                Row {
                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    StyledButton {
                        iconButton: "cancel"
                        buttonTitle: "No"
                        buttonColor: "transparent"
                        onClicked: root.rejected()
                    }

                    StyledButton {
                        iconButton: "check"
                        buttonTitle: "Yes"
                        buttonTextColor: Themes.m3Colors.m3OnPrimary
                        onClicked: root.accepted()
                    }
                }
            }
        }
    }
}
