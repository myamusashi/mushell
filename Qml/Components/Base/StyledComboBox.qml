pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

ComboBox {
    id: root

    readonly property string displayText_: {
        if (root.currentIndex < 0)
            return root.placeholderText;
        const m = root.model;
        if (!m)
            return root.placeholderText;
        const item = m.get ? m.get(root.currentIndex) : m[root.currentIndex];
        if (!item)
            return root.placeholderText;
        return item[root.textRole] ?? root.placeholderText;
    }
    property string placeholderText: qsTr("Select…")
    property real popupMaxHeight: 280
    property var isItemEnabled: modelData => true
    property var disabledLabel: modelData => qsTr("N/A")
    property var isItemActive: (modelData, itemIndex) => itemIndex === root.currentIndex

    textRole: "display"
    valueRole: ""
    onCurrentValueChanged: syncIndex()
    onModelChanged: syncIndex()
    onValueRoleChanged: syncIndex()
    Component.onCompleted: syncIndex()

    function syncIndex() {
        if (root.valueRole === "" || root.currentValue === null || root.currentValue === undefined)
            return;
        const count = root.model?.count ?? root.model?.length ?? 0;
        for (let i = 0; i < count; i++) {
            const item = root.model[i];
            if (!item)
                continue;
            const v = item[root.valueRole];
            if (v === root.currentValue) {
                root.currentIndex = i;
                return;
            }
        }
    }

    contentItem: WrapperItem {
        implicitHeight: 48
        leftMargin: Appearance.margin.normal

        StyledText {
            width: parent.width - x - root.indicator.width - 16
            text: root.displayText_
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnSecondaryContainer
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    background: StyledRect {
        implicitWidth: 280
        implicitHeight: 48
        color: Colours.m3Colors.m3Surface
        border.color: Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
        border.width: 1
    }

    indicator: Item {
        x: root.width - width - 16
        y: (root.height - height) / 2
        implicitWidth: 24
        implicitHeight: 24

        Icon {
            anchors.centerIn: parent
            icon: "keyboard_arrow_down"
            font.pixelSize: Appearance.fonts.size.extraLarge
            color: Colours.m3Colors.m3OnSecondaryContainer
            rotation: root.popup.visible ? 180 : 0

            Behavior on rotation {
                NAnim {}
            }
        }
    }

    popup: Popup {
        y: root.height + 4
        implicitWidth: root.width
        implicitHeight: Math.min(itemListView.contentHeight + 16, root.popupMaxHeight)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            id: bgPopup

            color: Colours.m3Colors.m3SurfaceContainerLow
            radius: Appearance.rounding.large

            Elevation {
                z: -1
                level: 2
                radius: bgPopup.radius
            }
        }

        contentItem: ListView {
            id: itemListView

            clip: true
            cacheBuffer: implicitHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.currentIndex

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: StyledRect {
                    implicitWidth: 4
                    radius: 2
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                }
            }

            header: Item {
                height: 8
            }
            footer: Item {
                height: 8
            }

            delegate: MenuDelegate {
                required property var modelData
                required property int index

                modelMenu: modelData
                indexMenu: index
                // qmllint disable
                itemEnabled: root.isItemEnabled(modelData)
                itemActive: root.isItemActive(modelData, index)
                // qmllint enable
            }
        }

        enter: Transition {
            NAnim {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animations.durations.small
            }
            NAnim {
                property: "scale"
                from: 0.95
                to: 1
                duration: Appearance.animations.durations.small
            }
        }
        exit: Transition {
            NAnim {
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.animations.durations.small
            }
        }
    }

    component MenuDelegate: ItemDelegate {
        id: menuDelegate

        required property var modelMenu
        required property int indexMenu
        required property bool itemEnabled
        required property bool itemActive

        width: itemListView.width
        height: 52
        leftPadding: 16
        rightPadding: 16
        topPadding: 0
        bottomPadding: 0
        highlighted: root.highlightedIndex === indexMenu
        enabled: itemEnabled

        background: StyledRect {
            id: menuBg
            property color c0From
            property color c0To
            property bool c0Active: false
            property real c0Blend: 1.0

            onC0BlendChanged: {
                if (!c0Active)
                    return;
                if (c0Blend >= 1) {
                    color = c0To;
                    c0Active = false;
                } else if (c0Blend > 0) {
                    color = Colours.blendColors(c0From, c0To, c0Blend);
                }
            }

            NAnim {
                id: c0Anim
                target: menuBg
                property: "c0Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            radius: Appearance.rounding.large
            property color menuBgTarget: menuDelegate.itemActive ? Colours.m3Colors.m3TertiaryContainer : "transparent"

            onMenuBgTargetChanged: {
                c0Anim.stop();
                c0From = menuBg.color;
                c0To = menuBgTarget;
                c0Active = true;
                c0Blend = 0.0;
                c0Anim.start();
            }
        }

        contentItem: BoxContent {
            modelMenu: menuDelegate.modelMenu
            itemEnabled: menuDelegate.itemEnabled
            itemActive: menuDelegate.itemActive
            highlighted: menuDelegate.highlighted
        }

        onClicked: {
            if (!menuDelegate.itemEnabled)
                return;
            root.currentIndex = indexMenu;
            root.activated(indexMenu);
            root.popup.close();
        }
    }

    component BoxContent: RowLayout {
        id: boxContent

        required property var modelMenu
        required property bool itemEnabled
        required property bool itemActive
        required property bool highlighted

        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.small

        StyledText {
            id: boxLabel
            property color c1From
            property color c1To
            property bool c1Active: false
            property real c1Blend: 1.0

            onC1BlendChanged: {
                if (!c1Active)
                    return;
                if (c1Blend >= 1) {
                    color = c1To;
                    c1Active = false;
                } else if (c1Blend > 0) {
                    color = Colours.blendColors(c1From, c1To, c1Blend);
                }
            }

            NAnim {
                id: c1Anim
                target: boxLabel
                property: "c1Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            Layout.fillWidth: true
            text: boxContent.modelMenu[root.textRole] ?? ""
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: boxContent.highlighted ? Font.Medium : Font.Normal
            property color boxLabelTarget: !boxContent.itemEnabled ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38) : boxContent.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            onBoxLabelTargetChanged: {
                c1Anim.stop();
                c1From = boxLabel.color;
                c1To = boxLabelTarget;
                c1Active = true;
                c1Blend = 0.0;
                c1Anim.start();
            }
        }

        Item {
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: Appearance.margin.large
        }

        BadgeComponent {
            Layout.alignment: Qt.AlignCenter
            modelMenu: parent.modelMenu
            itemEnabled: parent.itemEnabled
        }
        CheckComponent {
            Layout.alignment: Qt.AlignCenter
            itemActive: parent.itemActive
        }
    }

    component BadgeComponent: Loader {
        id: badgeComponent

        required property var modelMenu
        required property bool itemEnabled

        active: !itemEnabled
        asynchronous: false
        sourceComponent: StyledRect {
            anchors.centerIn: parent
            radius: Appearance.rounding.normal

            StyledText {
                id: badgeLabel

                anchors.centerIn: parent
                text: root.disabledLabel(badgeComponent.modelMenu) // qmllint disable
                font.pixelSize: Appearance.fonts.size.small
                font.weight: Font.Medium
                color: Colours.m3Colors.m3Error
            }
        }
    }

    component CheckComponent: Loader {
        id: checkComponent

        required property bool itemActive

        active: itemActive
        asynchronous: false
        sourceComponent: Icon {
            anchors.centerIn: parent
            icon: "check"
            font.pixelSize: Appearance.fonts.size.large * 1.3
            color: Colours.m3Colors.m3Primary
            visible: checkComponent.itemActive
            scale: visible ? 1.0 : 0.0

            Behavior on scale {
                NAnim {}
            }
        }
    }
}
