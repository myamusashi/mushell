pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

MaterialShape {
    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Circle

    Cookie {
        ColumnLayout {
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 20
            }
            z: 99

            RowLayout {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                Icon {
                    type: Icon.Material
                    icon: "visibility"
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                    color: Colours.m3Colors.m3OnSurface
                }

                StyledText {
                    text: "Visibility"
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurface
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Weather.visibility.toFixed(0)
                font.pixelSize: Appearance.fonts.size.extraLarge
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Km"
                font.pixelSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface
            }
        }
    }

    component Cookie: Item {
        anchors.centerIn: parent
        implicitWidth: 135
        implicitHeight: 135

        MaterialShape {
            anchors.centerIn: parent
            implicitWidth: 135
            implicitHeight: 135
            color: Colours.m3Colors.m3Primary
            opacity: 0.5
            shape: MaterialShape.Cookie12Sided
            z: 3
        }

        MaterialShape {
            anchors.centerIn: parent
            implicitWidth: 135
            implicitHeight: 135
            color: Colours.m3Colors.m3Primary
            opacity: 0.3
            shape: MaterialShape.Cookie12Sided
            rotation: 7
            z: 2
        }

        MaterialShape {
            anchors.centerIn: parent
            implicitWidth: 135
            implicitHeight: 135
            color: Colours.m3Colors.m3Primary
            opacity: 0.2
            shape: MaterialShape.Cookie12Sided
            rotation: 10
            z: 1
        }
    }
}
