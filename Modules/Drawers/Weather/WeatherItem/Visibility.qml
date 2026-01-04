pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "../../../../Submodules/rounded-polygon-qmljs/material-shapes.js" as MaterialShapes

ShapeCanvas {
    color: Colours.m3Colors.m3SurfaceContainer
    roundedPolygon: MaterialShapes.getCircle()
    onProgressChanged: requestPaint()

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
                    font.pointSize: Appearance.fonts.size.large
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

        ShapeCanvas {
            anchors.centerIn: parent
            implicitWidth: 135
            implicitHeight: 135
            color: Colours.withAlpha(Colours.m3Colors.m3Primary, 0.6)
            roundedPolygon: MaterialShapes.getCookie12Sided()
            onProgressChanged: requestPaint()
            z: 3
        }

        ShapeCanvas {
            anchors.centerIn: parent
            implicitWidth: 135
            implicitHeight: 135
            color: Colours.withAlpha(Colours.m3Colors.m3Primary, 0.5)
            roundedPolygon: MaterialShapes.getCookie12Sided()
            onProgressChanged: requestPaint()
            rotation: 7
            z: 2
        }

        ShapeCanvas {
            anchors.centerIn: parent
            implicitWidth: 135
            implicitHeight: 135
            color: Colours.withAlpha(Colours.m3Colors.m3Primary, 0.2)
            roundedPolygon: MaterialShapes.getCookie12Sided()
            onProgressChanged: requestPaint()
            rotation: 10
            z: 1
        }
    }
}
