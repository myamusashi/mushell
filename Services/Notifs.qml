pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import qs.Helpers

// Thanks to Caelestia once again for your amazing code: https://github.com/caelestia-dots/shell/blob/main/modules/notifications/Notification.qml
Singleton {
    id: root

    property list<Notif> list: []
    readonly property list<Notif> notClosed: list.filter(n => !n.closed)
    readonly property list<Notif> popups: list.filter(n => n.popup)
    property alias dnd: persistentProps.dnd
    property bool loaded: false

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 50
        onTriggered: {
            storage.setText(JSON.stringify(root.notClosed.map(n => ({
                        time: n.time.getTime(),
                        id: n.id,
                        summary: n.summary,
                        body: n.body,
                        appIcon: n.appIcon,
                        appName: n.appName,
                        image: n.image,
                        expireTimeout: n.expireTimeout,
                        urgency: n.urgency,
                        resident: n.resident,
                        hasActionIcons: n.hasActionIcons,
                        actions: n.actions
                    })), null, 2));
        }
    }

    PersistentProperties {
        id: persistentProps

        property bool dnd: false
        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const comp = notifComponent.createObject(root, {
                popup: !persistentProps.dnd,
                notification: notif
            });

            if (comp) {
                root.list = [comp, ...root.list];
            }
        }
    }

    FileView {
        id: storage

        path: Paths.cacheDir + "/mushell/notifications.json"

        onLoaded: {
            try {
                const content = text();
                if (!content || content.trim() === "") {
                    console.log("No cached notifications found");
                    root.loaded = true;
                    return;
                }

                const data = JSON.parse(content);
                if (!Array.isArray(data)) {
                    console.error("Invalid notification cache format");
                    root.loaded = true;
                    return;
                }

                for (const notifData of data) {
                    const notif = notifComponent.createObject(root, {
                        time: new Date(notifData.time),
                        id: notifData.id,
                        summary: notifData.summary,
                        body: notifData.body,
                        appIcon: notifData.appIcon,
                        appName: notifData.appName,
                        image: notifData.image,
                        expireTimeout: notifData.expireTimeout,
                        urgency: notifData.urgency,
                        resident: notifData.resident,
                        hasActionIcons: notifData.hasActionIcons,
                        actions: notifData.actions
                    });

                    if (notif) {
                        root.list.push(notif);
                    }
                }

                root.list.sort((a, b) => b.time - a.time);
                console.log(`Loaded ${root.list.length} notification(s) from cache`);
                root.loaded = true;
            } catch (error) {
                console.error("Failed to load notifications:", error);
                root.loaded = true;
            }
        }

        onLoadFailed: error => {
            console.log("Notification cache doesn't exist, creating it");
            setText("[]");
            root.loaded = true;
        }
    }

    function clearAll() {
        for (const notif of root.list.slice())
            notif.close();
    }

    component Notif: QtObject {
        id: notif

        property bool popup: false
        property bool closed: false

        property date time: new Date()
        readonly property string timeStr: {
            const diff = Time.date.getTime() - time.getTime();
            const m = Math.floor(diff / 60000);

            if (m < 1)
                return qsTr("now");

            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0)
                return `${d}d`;
            if (h > 0)
                return `${h}h`;
            return `${m}m`;
        }

        property Notification notification
        property string id: ""
        property string summary: ""
        property string body: ""
        property string appIcon: ""
        property string appName: ""
        property string image: ""
        property real expireTimeout: 5000
        property int urgency: NotificationUrgency.Normal
        property bool resident: false
        property bool hasActionIcons: false
        property list<var> actions: []

        readonly property Connections conn: Connections {
            target: notif.notification

            function onClosed() {
                notif.close();
            }

            function onSummaryChanged() {
                notif.summary = notif.notification.summary;
            }

            function onBodyChanged() {
                notif.body = notif.notification.body;
            }

            function onAppIconChanged() {
                notif.appIcon = notif.notification.appIcon;
            }

            function onAppNameChanged() {
                notif.appName = notif.notification.appName;
            }

            function onImageChanged() {
                notif.image = notif.notification.image;
            }

            function onExpireTimeoutChanged() {
                notif.expireTimeout = notif.notification.expireTimeout;
            }

            function onUrgencyChanged() {
                notif.urgency = notif.notification.urgency;
            }

            function onResidentChanged() {
                notif.resident = notif.notification.resident;
            }

            function onHasActionIconsChanged() {
                notif.hasActionIcons = notif.notification.hasActionIcons;
            }

            function onActionsChanged() {
                notif.actions = notif.notification.actions.map(a => ({
                            identifier: a.identifier,
                            text: a.text,
                            invoke: () => a.invoke()
                        }));
            }
        }

        function close() {
            closed = true;
            if (root.list.includes(this)) {
                root.list = root.list.filter(n => n !== this);
                if (notification)
                    notification.dismiss();
                destroy();
            }
        }

        Component.onCompleted: {
            if (!notification)
                return;

            id = notification.id;
            summary = notification.summary;
            body = notification.body;
            appIcon = notification.appIcon;
            appName = notification.appName;
            image = notification.image;
            expireTimeout = notification.expireTimeout;
            urgency = notification.urgency;
            resident = notification.resident;
            hasActionIcons = notification.hasActionIcons;
            actions = notification.actions.map(a => ({
                        identifier: a.identifier,
                        text: a.text,
                        invoke: () => a.invoke()
                    }));
        }
    }

    Component {
        id: notifComponent

        Notif {}
    }
}
