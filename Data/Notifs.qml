pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell.Services.Notifications
import Quickshell
import QtQuick

Singleton {
	component NotificationManagerComponent: QtObject {
		id: root

		readonly property var notificationCount: popupNotifications.length
		property list<QtObject> popupNotifications: []
		property list<QtObject> listNotifications: []
		property bool disabledDnD: false
		property NotificationServer server: NotificationServer {
			actionIconsSupported: true
			actionsSupported: true
			bodyHyperlinksSupported: true
			bodyImagesSupported: true
			bodyMarkupSupported: true
			bodySupported: true
			imageSupported: true
			persistenceSupported: true
			onNotification: function (notification) {
				notification.tracked = true;
				root.listNotifications.push(notification);
				root.popupNotifications.push(notification);
			}
		}
		function removePopupNotification(notification) {
			var newList = [];
			for (var i = 0; i < popupNotifications.length; i++)
				if (popupNotifications[i] !== notification)
					newList.push(popupNotifications[i]);

			popupNotifications = newList;
		}

		function removeListNotification(notification) {
			var newList = [];
			for (var i = 0; i < listNotifications.length; i++)
				if (listNotifications[i] !== notification)
					newList.push(listNotifications[i]);

			listNotifications = newList;
		}

		function dismiss() {
			if (popupNotifications.length > 0)
				popupNotifications[0].dismiss();
			if (listNotifications.length > 0)
				listNotifications[0].dismiss();
		}

		function dismissAll() {
			for (var i = 0; i < popupNotifications.length; i++)
				popupNotifications[i].dismiss();

			for (var i = 0; i < listNotifications.length; i++)
				listNotifications[i].dismiss();

			popupNotifications = [];
			listNotifications = [];
		}
	}

	readonly property NotificationManagerComponent notifications: NotificationManagerComponent {}
}
