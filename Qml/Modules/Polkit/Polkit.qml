pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Dialog
import qs.Services

DialogBox {
    id: root

    needKeyboardFocus: true
    activeAsync: PolAgent.agent?.isActive
    header: Header {}
    body: Body {
        id: bodyPolkit

        Connections {
            target: root

            function onActiveChanged() {
                bodyPolkit.passwordInput.focus = true;
                bodyPolkit.passwordInput.forceActiveFocus();
            }

            function onAccepted() {
                PolAgent.agent?.flow?.submit(bodyPolkit.passwordInput.text); // qmllint disable
            }

            function onRejected() {
                PolAgent.agent?.flow?.cancelAuthenticationRequest(); // qmllint disable
            }
        }
    }
}
