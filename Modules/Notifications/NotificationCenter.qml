pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Notifications

import qs.Data
import qs.Helpers
import qs.Components

Scope {
    id: scope

    property bool isNotificationCenterOpen: false

    LazyLoader {
        active: scope.isNotificationCenterOpen

        component: PanelWindow {
            id: root

            anchors {
                top: true
                right: true
            }

            property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
            property real monitorWidth: monitor.width / monitor.scale
            property real monitorHeight: monitor.height / monitor.scale
            implicitWidth: monitorWidth * 0.25
            implicitHeight: monitorHeight * 0.8
            exclusiveZone: 1

            color: "transparent"

            margins {
                right: 30
                left: (monitorWidth - implicitWidth) / 1.5
            }

            StyledRect {
                id: container

                anchors.fill: parent
                color: Themes.colors.surface

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.normal

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: header.height + 30
                        Layout.margins: 5
                        Layout.alignment: Qt.AlignTop
                        color: "transparent"

                        RowLayout {
                            id: header

                            anchors.fill: parent
                            anchors.margins: 10

                            StyledText {
                                Layout.fillWidth: true
                                text: "Notifications"
                                color: Themes.colors.on_background
                                font.pixelSize: Appearance.fonts.large * 1.2
                                font.weight: Font.Medium
                            }

                            Repeater {
                                model: [{
                                        "icon": "clear_all",
                                        "action": () => {
                                            Notifs.notifications.dismissAll()
                                        }
                                    }, {
                                        "icon": Notifs.notifications.disabledDnD ? "notifications_off" : "notifications_active",
                                        "action": () => {
                                            Notifs.notifications.disabledDnD
                                            = !Notifs.notifications.disabledDnD
                                        }
                                    }]

                                delegate: StyledRect {
                                    id: notifHeaderDelegate

                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    radius: 6
                                    color: iconMouse.containsMouse ? Themes.colors.surface_container_high : "transparent"

                                    required property var modelData

                                    MatIcon {
                                        anchors.centerIn: parent
                                        icon: notifHeaderDelegate.modelData.icon
                                        font.pixelSize: Appearance.fonts.large * 1.6
                                        color: Themes.colors.on_surface
                                    }

                                    MArea {
                                        id: iconMouse

                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: notifHeaderDelegate.modelData.action()
                                    }
                                }
                            }
                        }
                    }

                    StyledRect {
                        color: Themes.colors.outline_variant
                        Layout.fillWidth: true
                        implicitHeight: 1
                    }

                    StyledRect {
                        id: notifRect

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: listViewNotifs

                            anchors.fill: notifRect
                            clip: true
                            spacing: 10
                            anchors.margins: 15

                            model: ScriptModel {
                                values: [...Notifs.notifications.listNotifications.map(
                                        a => a)].reverse()
                            }

                            add: Transition {
                                NumbAnim {
                                    properties: "opacity"
                                    from: 0
                                    to: 1
                                }
                            }

                            remove: Transition {
                                NumbAnim {
                                    properties: "opacity"
                                    to: 0
                                }
                            }

                            displaced: Transition {
                                NumbAnim {
                                    properties: "y"
                                }
                            }

                            delegate: Flickable {
                                id: flickDelegate

                                property bool isShowMoreBody: false

                                width: listViewNotifs.width
                                height: Math.max(
                                            120,
                                            contentLayout.implicitHeight + 32)

                                implicitWidth: listViewNotifs.width
                                contentHeight: contentLayout.implicitHeight
                                boundsBehavior: Flickable.DragAndOvershootBounds
                                flickableDirection: Flickable.HorizontalFlick

                                required property Notification modelData

                                property bool hasImage: modelData?.image.length > 0
                                property bool hasAppIcon: modelData?.appIcon.length > 0

                                Behavior on x {
                                    NumbAnim {
                                        duration: Appearance.animations.durations.small
                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                    }
                                }

                                Behavior on y {
                                    NumbAnim {
                                        duration: Appearance.animations.durations.small
                                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                    }
                                }

                                Behavior on opacity {
                                    NumbAnim {
                                        duration: Appearance.animations.durations.small
                                        easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                                    }
                                }

                                RetainableLock {
                                    object: flickDelegate.modelData
                                    locked: true
                                }

                                StyledRect {
                                    id: rectNotification

                                    width: listViewNotifs.width
                                    height: Math.max(
                                                120,
                                                contentLayout.implicitHeight + 32)
                                    color: flickDelegate.modelData?.urgency
                                           === NotificationUrgency.Critical ? Themes.colors.error_container : Themes.colors.surface_container_low
                                    radius: Appearance.rounding.normal

                                    Behavior on implicitWidth {
                                        NumbAnim {}
                                    }

                                    MArea {
                                        id: delegateMouseNotif

                                        anchors.fill: parent
                                        hoverEnabled: true

                                        drag {
                                            axis: Drag.XAxis
                                            target: flickDelegate

                                            onActiveChanged: {
                                                if (delegateMouseNotif.drag.active)
                                                return

                                                if (Math.abs(flickDelegate.x)
                                                    > (flickDelegate.width * 0.45)) {
                                                    Notifs.notifications.removePopupNotification(
                                                        flickDelegate.modelData)
                                                    Notifs.notifications.removeListNotification(
                                                        flickDelegate.modelData)
                                                } else
                                                flickDelegate.x = 0
                                            }
                                        }
                                    }

                                    RowLayout {
                                        id: contentLayout

                                        anchors.fill: parent
                                        anchors.margins: 16
                                        anchors.topMargin: 10
                                        anchors.leftMargin: 35
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                                        spacing: 8

                                        Item {
                                            Layout.alignment: Qt.AlignCenter
                                            Layout.rightMargin: 40
                                            Layout.preferredWidth: 65
                                            Layout.preferredHeight: 65

                                            Loader {
                                                id: appIcon

                                                active: flickDelegate.hasAppIcon
                                                        || !flickDelegate.hasImage
                                                asynchronous: true

                                                anchors.centerIn: parent
                                                width: 65
                                                height: 65
                                                sourceComponent: StyledRect {
                                                    width: 65
                                                    height: 65
                                                    radius: Appearance.rounding.full
                                                    color: flickDelegate.modelData?.urgency === NotificationUrgency.Critical ? Themes.colors.error : flickDelegate.modelData?.urgency === NotificationUrgency.Low ? Themes.colors.surface_container_highest : Themes.colors.secondary_container

                                                    Loader {
                                                        id: icon

                                                        active: flickDelegate?.hasAppIcon
                                                        asynchronous: true

                                                        anchors.centerIn: parent
                                                        width: 65
                                                        height: 65
                                                        sourceComponent: IconImage {
                                                            anchors.centerIn: parent
                                                            source: Quickshell.iconPath(
                                                                        flickDelegate.modelData?.appIcon)
                                                        }
                                                    }

                                                    Loader {
                                                        active: !flickDelegate.hasAppIcon
                                                        asynchronous: true

                                                        anchors.centerIn: parent
                                                        anchors.horizontalCenterOffset: -Appearance.fonts.large * 0.02
                                                        anchors.verticalCenterOffset: Appearance.fonts.large * 0.02
                                                        sourceComponent: MatIcon {
                                                            text: "release_alert"
                                                            color: flickDelegate.modelData?.urgency === NotificationUrgency.Critical ? Themes.colors.on_error : flickDelegate.modelData?.urgency === NotificationUrgency.Low ? Themes.colors.on_surface : Themes.colors.on_secondary_container
                                                            font.pointSize: Appearance.fonts.large
                                                        }
                                                    }
                                                }
                                            }

                                            Loader {
                                                id: image

                                                active: flickDelegate.hasImage
                                                asynchronous: true

                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                                anchors.rightMargin: -5
                                                anchors.bottomMargin: -5
                                                width: 28
                                                height: 28
                                                z: 1

                                                sourceComponent: StyledRect {
                                                    width: 28
                                                    height: 28
                                                    radius: width / 2
                                                    color: "white"
                                                    border.color: Themes.colors.surface
                                                    border.width: 2

                                                    ClippingRectangle {
                                                        anchors.centerIn: parent
                                                        radius: width / 2
                                                        width: 24
                                                        height: 24

                                                        Image {
                                                            anchors.fill: parent

                                                            source: Qt.resolvedUrl(
                                                                        flickDelegate.modelData?.image)
                                                            fillMode: Image.PreserveAspectCrop
                                                            cache: false
                                                            asynchronous: true

                                                            layer.enabled: true
                                                            layer.effect: MultiEffect {
                                                                maskEnabled: true

                                                                maskSource: StyledRect {
                                                                    width: 24
                                                                    height: 24
                                                                    radius: width / 2
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignTop
                                            spacing: 4

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.rightMargin: 5

                                                Item {
                                                    Layout.fillWidth: true

                                                    RowLayout {
                                                        y: -10
                                                        Layout.alignment: Qt.AlignTop

                                                        StyledText {
                                                            id: appName

                                                            Layout.fillWidth: true
                                                            text: flickDelegate.modelData?.appName
                                                            font.pixelSize: Appearance.fonts.small * 0.9
                                                            color: Themes.colors.on_background
                                                            elide: Text.ElideRight
                                                        }

                                                        StyledText {
                                                            id: dots

                                                            text: "•"
                                                            color: Themes.colors.on_surface_variant
                                                            font.pixelSize: Appearance.fonts.large
                                                        }

                                                        StyledText {
                                                            id: whenTime

                                                            property date currentTime: new Date()
                                                            text: TimeAgo.timeAgoWithIfElse(
                                                                      currentTime)
                                                            color: Themes.colors.on_surface_variant

                                                            Timer {
                                                                interval: 60000
                                                                running: true
                                                                repeat: true
                                                                onTriggered: whenTime.currentTime = new Date()
                                                            }
                                                        }
                                                    }
                                                }

                                                StyledRect {
                                                    id: expandButton

                                                    Layout.preferredWidth: 32
                                                    Layout.preferredHeight: 32

                                                    radius: Appearance.rounding.large
                                                    color: expandButtonMouse.pressed ? Themes.colors.secondary_container : expandButtonMouse.containsMouse ? Themes.withAlpha(Themes.colors.on_surface, 0.08) : "transparent"

                                                    MatIcon {
                                                        id: expandIcon

                                                        anchors.centerIn: parent
                                                        icon: flickDelegate.isShowMoreBody ? "expand_less" : "expand_more"
                                                        font.pixelSize: Appearance.fonts.large + 5
                                                        color: Themes.colors.on_surface_variant

                                                        Behavior on rotation {
                                                            RotationAnimation {
                                                                duration: Appearance.animations.durations.normal
                                                                easing.type: Easing.BezierSpline
                                                                easing.bezierCurve: Appearance.animations.curves.standard
                                                            }
                                                        }
                                                    }

                                                    MArea {
                                                        id: expandButtonMouse

                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            flickDelegate.isShowMoreBody
                                                            = !flickDelegate.isShowMoreBody
                                                        }
                                                    }
                                                }
                                            }

                                            StyledText {
                                                id: summary

                                                Layout.fillWidth: true
                                                text: flickDelegate.modelData?.summary
                                                font.pixelSize: Appearance.fonts.normal * 1.1
                                                font.weight: Font.DemiBold
                                                color: Themes.colors.on_surface
                                                elide: Text.ElideRight
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                            }

                                            StyledText {
                                                id: body

                                                Layout.fillWidth: true
                                                text: flickDelegate.modelData?.body
                                                      || ""
                                                font.pixelSize: Appearance.fonts.small * 1.1
                                                lineHeight: 1.4
                                                color: Themes.colors.on_surface_variant
                                                Layout.preferredWidth: parent.width
                                                elide: Text.ElideRight
                                                textFormat: flickDelegate.isShowMoreBody ? Text.MarkdownText : Text.StyledText
                                                wrapMode: flickDelegate.isShowMoreBody ? Text.WrapAtWordBoundaryOrAnywhere : Text.Wrap
                                                maximumLineCount: flickDelegate.isShowMoreBody ? 0 : 1
                                                visible: text.length > 0
                                                clip: true

                                                transformOrigin: Item.Top

                                                opacity: flickDelegate.isShowMoreBody ? 1.0 : 0.92
                                                Behavior on opacity {
                                                    NumbAnim {
                                                        duration: Appearance.animations.durations.small
                                                        easing.type: Easing.OutQuad
                                                    }
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.topMargin: 8
                                                spacing: 8
                                                visible: flickDelegate.modelData?.actions
                                                         && flickDelegate.modelData?.actions.length > 0

                                                Repeater {
                                                    model: flickDelegate.modelData?.actions
                                                           ?? []

                                                    delegate: StyledRect {
                                                        id: actionButton

                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 36

                                                        required property NotificationAction modelData

                                                        color: actionMouse.pressed ? Themes.colors.secondary_container : actionMouse.containsMouse ? Themes.colors.secondary_container : Themes.colors.surface_container_high
                                                        radius: Appearance.rounding.small

                                                        StyledRect {
                                                            anchors.fill: parent

                                                            anchors.topMargin: 1
                                                            color: actionMouse.pressed ? Themes.withAlpha(Themes.colors.on_secondary_container, 0.12) : actionMouse.containsMouse ? Themes.withAlpha(Themes.colors.on_secondary_container, 0.08) : "transparent"
                                                            radius: parent.radius
                                                            visible: !actionMouse.pressed
                                                        }

                                                        MArea {
                                                            id: actionMouse

                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor

                                                            onClicked: {
                                                                actionButton.modelData.invoke()
                                                                Notifs.notifications.removePopupNotification(
                                                                    flickDelegate.modelData)
                                                                Notifs.notifications.removeListNotification(
                                                                    flickDelegate.modelData)
                                                                flickDelegate.modelData?.dismiss()
                                                            }

                                                            StyledRect {
                                                                id: ripple

                                                                anchors.centerIn: parent

                                                                width: 0
                                                                height: 0
                                                                radius: width / 2
                                                                color: Themes.withAlpha(
                                                                           Themes.colors.primary,
                                                                           0.3)
                                                                visible: false

                                                                SequentialAnimation {
                                                                    id: rippleAnimation

                                                                    PropertyAnimation {
                                                                        target: ripple
                                                                        property: "width"
                                                                        to: Math.max(actionButton.width, actionButton.height) * 2
                                                                        duration: Appearance.animations.durations.normal * 1.2
                                                                        easing.type: Easing.BezierSpline
                                                                        easing.bezierCurve: Appearance.animations.curves.standard
                                                                    }
                                                                    PropertyAnimation {
                                                                        target: ripple
                                                                        property: "height"
                                                                        to: ripple.width
                                                                        duration: 0
                                                                    }
                                                                    PropertyAnimation {
                                                                        target: ripple
                                                                        property: "opacity"
                                                                        to: 0
                                                                        duration: 200
                                                                    }
                                                                    onStarted: {
                                                                        ripple.visible = true
                                                                        ripple.opacity = 1
                                                                    }
                                                                    onFinished: {
                                                                        ripple.visible = false
                                                                        ripple.width = 0
                                                                        ripple.height = 0
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        StyledText {
                                                            id: actionText

                                                            anchors.centerIn: parent
                                                            text: actionButton.modelData.text
                                                            font.pixelSize: Appearance.fonts.small * 1.1
                                                            font.weight: actionMouse.containsMouse ? Font.Medium : Font.Normal
                                                            color: actionMouse.containsMouse ? Themes.colors.on_primary_container : Themes.colors.on_surface
                                                            elide: Text.ElideRight
                                                        }

                                                        Behavior on color {
                                                            ColAnim {}
                                                        }
                                                        Behavior on border.color {
                                                            ColAnim {}
                                                        }
                                                        Behavior on border.width {
                                                            NumbAnim {}
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
