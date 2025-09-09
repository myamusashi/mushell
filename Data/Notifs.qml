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
		property int maxVisible: 5
		property bool isDnDDisabled: false
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
				console.log("Dapet notifikasi", notification.appName, "-", notification.summary);
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
			notification.dismiss();
		}

		function removeListNotification(notification) {
			var newList = [];
			for (var i = 0; i < listNotifications.length; i++)
				if (listNotifications[i] !== notification)
					newList.push(listNotifications[i]);

			listNotifications = newList;
			notification.dismiss();
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
