pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Dialog
import qs.Core.Configs
import qs.Services

DialogBox {
    id: root

    needKeyboardFocus: true
    activeAsync: PolAgent.agent?.isActive

    // Compact card proportions for the auth prompt.
    cardPaddingWidth: 36
    cardPaddingHeight: 24
    contentMinWidth: 280
    contentSpacing: Appearance.spacing.normal

    header: Header {}
    body: Body {
        id: bodyPolkit

        Connections {
            target: root

            function onActiveChanged() {
                if (!root.active)
                    return;

                bodyPolkit.passwordInput.forceActiveFocus();
            }

            function onAccepted() {
                bodyPolkit.submit();
            }

            function onRejected() {
                bodyPolkit.cancel();
            }
        }
    }
}
