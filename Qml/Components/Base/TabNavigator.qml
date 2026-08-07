pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property Item scope: null
    property Item defaultItem: null

    function focusables() {
        const list = [];
        root.collect(root.scope, list);
        list.sort((a, b) => {
            const ap = a.mapToScene(0, 0);
            const bp = b.mapToScene(0, 0);
            if (ap.y !== bp.y)
                return ap.y - bp.y;
            return ap.x - bp.x;
        });
        return list;
    }

    // qmllint disable
    function collect(item, out) {
        if (item === null || item === undefined)
            return;
        if (typeof item.keyboardFocusable === "boolean" && item.keyboardFocusable === true && item.enabled !== false)
            out.push(item);

        try {
            if (item.contentItem !== undefined && item.contentItem !== null && item.contentItem !== item)
                root.collect(item.contentItem, out);

            const data = item.data;
            if (Array.isArray(data)) {
                for (const child of data)
                    root.collect(child, out);
            }
        } catch (err) {}
    }

    function isFocused(item) {
        if (!item)
            return false;
        if (item.activeFocus)
            return true;
        const winItem = item.window ? item.window.activeFocusItem : null;
        return winItem !== null && item.isAncestorOf(winItem);
    }
    // qmllint enable

    function move(delta) {
        const list = root.focusables();
        if (list.length === 0)
            return;

        let idx = list.findIndex(i => root.isFocused(i));
        if (idx < 0)
            idx = delta > 0 ? -1 : 0;

        const target = ((idx + delta) % list.length + list.length) % list.length;
        root.activate(list[target]);
    }

    function next() {
        root.move(1);
    }

    function previous() {
        root.move(-1);
    }

    function activate(item) {
        if (typeof item.requestKeyboardFocus === "function")
            item.requestKeyboardFocus();
        else
            item.forceActiveFocus();
    }

    function firstFocus() {
        const list = root.focusables();
        if (list.length === 0)
            return;
        if (root.defaultItem !== null && root.defaultItem !== undefined && list.indexOf(root.defaultItem) >= 0)
            root.activate(root.defaultItem);
        else
            root.activate(list[0]);
    }
}
