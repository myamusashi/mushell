pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import qs.Configs
import qs.Helpers
import qs.Components

Item {
	id: root

    required property Notification modelData
    property bool hasImage: modelData.image.length > 0
    property bool hasAppIcon: modelData.appIcon.length > 0
    width: 40
    height: 40

    Loader {
		id: appIcon

        active: root.hasAppIcon || !root.hasImage
        anchors.centerIn: parent
        width: 40
        height: 40
        sourceComponent: StyledRect {
            width: 40
            height: 40
            radius: Appearance.rounding.full
            color: root.modelData.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3Error : root.modelData.urgency === NotificationUrgency.Low ? Themes.m3Colors.m3SecondaryContainer : Themes.m3Colors.m3PrimaryContainer

            Loader {
				id: icon

                active: root.hasAppIcon
                anchors.centerIn: parent
                width: 24
                height: 24
                sourceComponent: Image {
                    width: 24
                    height: 24
                    source: Quickshell.iconPath(root.modelData.appIcon)
                    fillMode: Image.PreserveAspectFit
                    cache: true
                    asynchronous: true
                    sourceSize: Qt.size(24, 24)
                }
            }

            Loader {
                active: !root.hasAppIcon
                anchors.centerIn: parent
                sourceComponent: MaterialIcon {
                    icon: "notifications_active"
                    color: root.modelData.urgency === NotificationUrgency.Critical ? Themes.m3Colors.m3OnError : root.modelData.urgency === NotificationUrgency.Low ? Themes.m3Colors.m3OnSecondaryContainer : Themes.m3Colors.m3OnPrimaryContainer
                    font.pointSize: Appearance.fonts.normal
                }
            }
        }
    }

    Loader {
		id: image

        active: root.hasImage
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -4
        anchors.bottomMargin: -4
        width: 20
        height: 20
        z: 1
        sourceComponent: StyledRect {
            width: 20
            height: 20
            radius: 10
            color: Themes.m3Colors.m3Surface
            border.color: Themes.m3Colors.m3OutlineVariant
            border.width: 1.5

            ClippingRectangle {
                anchors.centerIn: parent
                radius: 8
                width: 16
                height: 16

                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl(root.modelData.image)
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    sourceSize: Qt.size(16, 16)

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: StyledRect {
                            width: 16
                            height: 16
                            radius: 8
                        }
                    }
                }
            }
        }
    }
}
