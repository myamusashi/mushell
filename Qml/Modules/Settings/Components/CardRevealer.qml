pragma ComponentBehavior: Bound

import QtQuick

import qs.Core.Configs

Item {
    id: root

    required property Flickable target
    required property Item container

    property string pendingTitle: ""

    // The page layout may still be settling right after a page switch, so
    // the scroll target is re-applied on every contentHeight change until
    // it stays quiet, keeping the card pinned below the top margin.
    function reveal(cardTitle: string): bool {
        const card = findCard(container, cardTitle);

        if (!card || !card.visible)
            return false;

        pendingTitle = cardTitle;
        scrollToCard(card);

        if (card.flash)
            card.flash();

        settleTimer.restart();
        return true;
    }

    function refreshPending() {
        if (pendingTitle === "")
            return;

        const card = findCard(container, pendingTitle);

        if (card && card.visible)
            scrollToCard(card);
        settleTimer.restart();
    }

    function scrollToCard(card) {
        const y = card.mapToItem(target.contentItem).y - Appearance.margin.large;

        scrollAnim.to = Math.max(0, Math.min(y, target.contentHeight - target.height));
        scrollAnim.restart();
    }

    function findCard(item, cardTitle) {
        if (item.title === cardTitle)
            return item;

        for (let i = 0; i < item.children.length; i++) {
            const found = findCard(item.children[i], cardTitle);
            if (found)
                return found;
        }
        return null;
    }

    Connections {
        target: root.target

        function onContentHeightChanged() {
            root.refreshPending();
        }
    }

    Timer {
        id: settleTimer

        interval: 120
        onTriggered: root.pendingTitle = ""
    }
    NumberAnimation {
        id: scrollAnim

        target: root.target
        property: "contentY"
        duration: 350
        easing.type: Easing.OutCubic
    }
}
