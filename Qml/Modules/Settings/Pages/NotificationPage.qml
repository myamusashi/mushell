import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Notification configurations")

    SettingsCard {
        title: qsTr("Notification Limits")

        SettingRow {
            label: qsTr("Maximum Notifications:")
            description: qsTr("Maximum number of stored notifications to keep.")

            StyledSlide {
                from: 10
                to: 500
                stepSize: 10
                value: Configs.notification.maximumNotification
                onMoved: Configs.notification.maximumNotification = value
                Layout.preferredWidth: 200
            }
        }

        SettingRow {
            label: qsTr("Maximum Notification Age (Days):")
            description: qsTr("Auto-remove notifications older than this many days.")

            StyledSlide {
                from: 1
                to: 30
                stepSize: 1
                value: Configs.notification.maximumNotificationAge / 86400000
                onMoved: Configs.notification.maximumNotificationAge = value * 86400000
                Layout.preferredWidth: 200
            }
        }
    }
}
