pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Menu

Popup {
    id: root

    property Item anchorItem: null
    property alias model: itemRepeater.model
    property int currentIndex: -1
    property var textRole: "text"
    property var isItemEnabled: modelData => true
    property var disabledLabel: modelData => ""
    property var isItemActive: (modelData, itemIndex) => itemIndex === root.currentIndex
    property bool showScrollBar: false

    signal activated(int index)

    padding: 0
    background: null
    focus: true
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
    transformOrigin: Popup.TopLeft

    width: root.anchorItem ? Math.max(menuSurface.minWidth, Math.min(menuSurface.maxWidth, root.anchorItem.width)) : menuSurface.implicitWidth
    y: root.anchorItem ? root.anchorItem.height + 4 : 0

    onAnchorItemChanged: {
        if (root.anchorItem)
            root.parent = root.anchorItem;
    }

    MenuSurface {
        id: menuSurface

        anchors.fill: parent
        showScrollBar: root.showScrollBar

        Repeater {
            id: itemRepeater

            model: root.model

            delegate: MenuItem {
                required property int index
                required property var modelData

                label: typeof modelData === "string" ? modelData : modelData[root.textRole] ?? ""
                // qmllint disable
                selected: root.isItemActive(modelData, index)
                disabledLabel: root.disabledLabel(modelData)
                enabled: root.isItemEnabled(modelData)
                // qmllint enable

                onTriggered: {
                    root.activated(index);
                    root.close();
                }
            }
        }
    }

    enter: Transition {
        ParallelAnimation {
            NAnim {
                property: "opacity"
                from: 0.0
                to: 1.0
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
            NAnim {
                property: "scale"
                from: 0.8
                to: 1.0
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NAnim {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
            NAnim {
                property: "scale"
                from: 1.0
                to: 0.8
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
        }
    }
}
