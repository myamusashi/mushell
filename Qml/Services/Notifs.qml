pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Vast.ImageCache

import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    property alias dnd: persistentProps.dnd

    readonly property list<Notif> notClosed: list.filter(n => !n.closed)
    readonly property list<Notif> popups: list.filter(n => n.popup)

    property list<Notif> list: []
    property bool loaded: false
    property int maxNotifications: 100
    property int maxNotificationAge: 604800000

    function clearAll() {
        for (const notif of root.list.slice())
            notif.close();
    }

    function forceCleanup() {
        const now = Date.now();
        for (const notif of root.list.slice()) {
            if (now - notif.time.getTime() > root.maxNotificationAge * 2) {
                notif.locks.clear();
                notif.close();
            }
        }
    }

    function cleanupOldNotifications() {
        const now = Date.now();
        const oldNotifications = root.list.filter(n => {
            const age = now - n.time.getTime();
            return age > root.maxNotificationAge;
        });

        if (oldNotifications.length > 0) {
            console.log(`Cleaning up ${oldNotifications.length} old notification(s)`);
            ToastService.show(qsTr("Cleaning up %1 old notification(s)").arg(oldNotifications.length), qsTr("Notifications"), "dialog-information", 3000);
            for (const notif of oldNotifications)
                notif.close();
        }
    }

    function enforceNotificationLimit() {
        cleanupOldNotifications();

        const currentCount = root.notClosed.length;

        if (currentCount >= root.maxNotifications) {
            const sortedNotifs = root.notClosed.slice().sort((a, b) => a.time - b.time);
            const toRemove = currentCount - root.maxNotifications + 1;

            console.log(`Removing ${toRemove} oldest notification(s) to enforce limit`);
            ToastService.show(qsTr("Removing %1 oldest notification(s) to enforce limit").arg(toRemove), qsTr("Notifications"), "dialog-information", 3000);
            for (let i = 0; i < toRemove && i < sortedNotifs.length; i++)
                sortedNotifs[i].close();
        }
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 2000
        onTriggered: {
            storage.setText(JSON.stringify(root.notClosed.map(n => {
                let persistentImage = n.image ?? "";

                if (persistentImage.startsWith("image://")) {
                    const key = "notif-" + n.id;
                    const cached = ImageCache.cachedPath(key);
                    persistentImage = cached || "";
                }

                return {
                    time: n.time.getTime(),
                    id: n.id,
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    appName: n.appName,
                    image: persistentImage,
                    desktopEntry: n.desktopEntry,
                    expireTimeout: n.expireTimeout,
                    urgency: n.urgency,
                    resident: n.resident,
                    hasActionIcons: n.hasActionIcons,
                    actions: n.actions
                };
            }), null, 2));
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.forceCleanup()
    }

    Timer {
        id: cleanupTimer

        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.cleanupOldNotifications()
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
        inlineReplySupported: true

        onNotification: notif => {
            notif.tracked = true;

            root.enforceNotificationLimit();

            const comp = notifComponent.createObject(root, {
                popup: !persistentProps.dnd,
                notification: notif
            });

            if (comp)
                root.list = [comp, ...root.list];
        }
    }

    FileView {
        id: storage

        path: Paths.cacheDir + "/mushell/notifications.json"

        onLoaded: {
            try {
                const content = text();
                if (!content || content.trim() === "") {
                    ToastService.show(qsTr("No cached notifications found"), qsTr("Notifications"));
                    console.log("No cached notifications found");
                    root.loaded = true;
                    return;
                }

                const data = JSON.parse(content);
                if (!Array.isArray(data)) {
                    console.error("Invalid notification cache format");
                    ToastService.show(qsTr("Invalid notification cache format"), qsTr("Notifications"), "dialog-error", 3000);
                    root.loaded = true;
                    return;
                }

                const now = Date.now();
                let loadedCount = 0;

                for (const notifData of data) {
                    const notifAge = now - notifData.time;
                    if (notifAge > root.maxNotificationAge)
                        continue;

                    const raw = notifData.image ?? "";
                    // image:// URLs are provider-ephemeral and cannot survive a reload;
                    // they should never appear in JSON after the saveTimer fix, but discard
                    // any that slipped through from an older cache.
                    const stableUrl = raw.startsWith("image://") ? "" : raw;

                    const notif = notifComponent.createObject(root, {
                        time: new Date(notifData.time),
                        id: notifData.id,
                        summary: notifData.summary,
                        body: notifData.body,
                        appIcon: notifData.appIcon,
                        appName: notifData.appName,
                        image: stableUrl,
                        desktopEntry: notifData.desktopEntry,
                        expireTimeout: notifData.expireTimeout,
                        urgency: notifData.urgency,
                        resident: notifData.resident,
                        hasActionIcons: notifData.hasActionIcons,
                        actions: notifData.actions
                    });

                    if (notif) {
                        root.list.push(notif);
                        loadedCount++;
                    }

                    if (loadedCount >= root.maxNotifications)
                        break;
                }

                root.list.sort((a, b) => b.time - a.time);
                console.log(`Loaded ${loadedCount} notification(s) from cache`);
                ToastService.show(qsTr("Loaded %1 notification(s) from cache").arg(loadedCount), qsTr("Notifications"), "dialog-information", 3000);
                root.loaded = true;
            } catch (error) {
                console.error("Failed to load notifications:", error);
                ToastService.show(qsTr("Failed to load notifications: %1").arg(error), qsTr("Notifications"), "dialog-error", 3000);
                root.loaded = true;
            }
        }

        onLoadFailed: error => {
            console.log("Notification cache doesn't exist, creating it");
            ToastService.show(qsTr("Notification cache doesn't exist, creating it"), qsTr("Notifications"), "dialog-information", 3000);
            setText("[]");
            root.loaded = true;
        }
    }

    component Notif: QtObject {
        id: notif

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
                const raw = notif.notification.image ?? "";

                if (!raw || raw === "") {
                    notif.image = "";
                    return;
                }

                if (raw.startsWith("image://")) {
                    if (raw.startsWith("image://icon//")) {
                        notif.image = "file:///" + raw.slice("image://icon//".length);
                    } else if (raw.startsWith("image://icon/")) {
                        notif.image = raw;
                    } else if (notif.notification && notif.notification.id) {
                        notif.image = ImageCache.saveProviderImageQml(raw, "notif-" + notif.notification.id);
                    }
                } else
                    notif.image = raw;
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

            function onHasInlineReplyChanged() {
                notif.hasInlineReply = notif.notification.hasInlineReply;
            }

            function onInlineReplyPlaceholderChanged() {
                notif.inlineReplyPlaceholder = notif.notification.inlineReplyPlaceholder;
            }

            function onActionsChanged() {
                notif.actions = notif.notification.actions.map(a => ({
                            identifier: a.identifier,
                            text: a.text,
                            invoke: () => a.invoke()
                        }));
            }
        }

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
        property bool popup: false
        property bool closed: false

        property date time: new Date()

        property string desktopEntry: ""

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
        property bool hasInlineReply: false
        property string inlineReplyPlaceholder: ""
        property list<var> actions: []
        property var locks: new Set()

        function lock(item) {
            locks.add(item);
        }

        function unlock(item) {
            locks.delete(item);
            if (closed)
                close();
        }

        function close() {
            closed = true;
            if (locks.size === 0 && root.list.includes(this)) {
                root.list = root.list.filter(n => n !== this);
                ImageCache.evictKey("notif-" + id);
                if (notification)
                    notification.dismiss();
                conn.target = null;
                destroy();
            }
        }

        function closeQuiet() {
            closed = true;
            if (locks.size === 0 && root.list.includes(this)) {
                root.list = root.list.filter(n => n !== this);
                if (notification)
                    notification.dismiss();
                conn.target = null;
                destroy();
            }
        }

        function sendInlineReply(text) {
            const trimmed = text.trim();

            if (!notification || closed || !hasInlineReply || trimmed === "")
                return;

            notification.sendInlineReply(trimmed);
        }

        function dismissPopup() {
            popup = false;
        }

        Component.onCompleted: {
            if (!notification)
                return;

            const raw = notification.image ?? "";
            let cachedImage = raw;
            if (raw.startsWith("image://")) {
                if (raw.startsWith("image://icon//"))
                    cachedImage = "file:///" + raw.slice("image://icon//".length);
                else if (raw.startsWith("image://icon/"))
                    cachedImage = raw;
                else
                    cachedImage = ImageCache.saveProviderImageQml(raw, "notif-" + notification.id);
            }

            id = notification.id;
            summary = notification.summary;
            body = notification.body;
            appIcon = notification.appIcon;
            appName = notification.appName;
            image = cachedImage;
            expireTimeout = notification.expireTimeout;
            urgency = notification.urgency;
            resident = notification.resident;
            hasActionIcons = notification.hasActionIcons;
            hasInlineReply = notification.hasInlineReply;
            inlineReplyPlaceholder = notification.inlineReplyPlaceholder;
            actions = notification.actions.map(a => ({
                        identifier: a.identifier,
                        text: a.text,
                        invoke: () => a.invoke()
                    }));
        }

        Component.onDestruction: {
            if (conn.target)
                conn.target = null;
        }
    }

    Component {
        id: notifComponent

        Notif {}
    }

    Component.onDestruction: {
        cleanupTimer.stop();
        for (const notif of root.list.slice()) {
            try {
                notif.closeQuiet();
            } catch (e) {
                console.error("Error cleaning up notification:", e);
            }
        }
    }
}
