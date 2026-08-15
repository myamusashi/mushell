pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property alias model: dropdownMenu.model
    property string textRole: "display"
    property string valueRole: ""
    property int currentIndex: -1
    property var currentValue: null
    property string placeholderText: qsTr("Select…")
    property var isItemEnabled: model => true
    property var disabledLabel: model => qsTr("N/A")
    property var isItemActive: (model, itemIndex) => itemIndex === root.currentIndex
    property bool showScrollBar: false

    signal activated(int index)

    implicitWidth: 280
    implicitHeight: 48

    readonly property string displayText: {
        if (root.currentIndex < 0 || !root.model)
            return root.placeholderText;
        const item = root.model.get ? root.model.get(root.currentIndex) : root.model[root.currentIndex];
        if (!item)
            return root.placeholderText;
        return item[root.textRole] ?? root.placeholderText;
    }

    onCurrentValueChanged: syncIndex()
    onModelChanged: syncIndex()
    onValueRoleChanged: syncIndex()
    Component.onCompleted: syncIndex()

    function syncIndex() {
        if (root.valueRole === "" || root.currentValue === null || root.currentValue === undefined)
            return;
        const model = root.model;
        if (!model)
            return;
        // C++ list models expose count()/get(i) as methods, JS models use length/indexing
        const count = typeof model.count === "function" ? model.count() : (model.count ?? model.length ?? 0);
        const getItem = typeof model.get === "function" ? i => model.get(i) : i => model[i];
        for (let i = 0; i < count; i++) {
            const item = getItem(i);
            if (!item)
                continue;
            const v = item[root.valueRole];
            if (v === root.currentValue) {
                root.currentIndex = i;
                return;
            }
        }
    }

    StyledRect {
        id: fieldSurface

        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Colours.m3Colors.m3Surface
        border.color: Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
        border.width: 1
    }

    MArea {
        layerRadius: Appearance.rounding.large
        onWheel: wheel => wheel.accepted = false

        onClicked: {
            if (dropdownMenu.opened)
                dropdownMenu.close();
            else
                dropdownMenu.open();
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.margin.normal
            anchors.rightMargin: Appearance.margin.normal
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.displayText
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Medium
                color: root.currentIndex < 0 ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
            }

            Item {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                transformOrigin: Item.Center

                rotation: dropdownMenu.opened ? 180 : 0

                Behavior on rotation {
                    NAnim {}
                }

                Icon {
                    anchors.centerIn: parent
                    icon: "keyboard_arrow_down"
                    font.pixelSize: Appearance.fonts.size.extraLarge
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    DropdownMenu {
        id: dropdownMenu

        anchorItem: root
        textRole: root.textRole
        currentIndex: root.currentIndex
        isItemEnabled: root.isItemEnabled
        disabledLabel: root.disabledLabel
        isItemActive: root.isItemActive
        showScrollBar: root.showScrollBar

        onActivated: index => {
            root.currentIndex = index;
            root.activated(index);
        }
    }
}
