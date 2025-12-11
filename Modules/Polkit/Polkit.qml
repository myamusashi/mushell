pragma ComponentBehavior: Bound

import QtQuick

import qs.Components
import qs.Services

DialogBox {
    id: root

    needKeyboardFocus: true
    activeAsync: PolAgent.agent.isActive
    header: Header {}
    body: Body {
        id: bodyPolkit

        Connections {
            target: root

            function onActiveChanged() {
                bodyPolkit.passwordInput.focus = true;
                bodyPolkit.passwordInput.forceActiveFocus();
            }
        }
    }

    onAccepted: PolAgent.agent?.flow?.submit(bodyPolkit.passwordInput.text)
    onRejected: PolAgent.agent?.flow?.cancelAuthenticationRequest()
}
