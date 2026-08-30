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

    property string text: ""
    property int textSize: Appearance.fonts.size.normal

    property var model: []
    property string textRole: "text"
    property alias currentIndex: menu.currentIndex

    property var isItemEnabled: modelData => true
    property var disabledLabel: modelData => ""

    property MenuIconComponent menuIcon: MenuIconComponent {}

    property color containerColor: Colours.m3Colors.m3SecondaryContainer
    property color contentColor: Colours.m3Colors.m3OnSecondaryContainer

    property IconComponent icon: IconComponent {}

    readonly property bool hasMenu: {
        if (model === null || model === undefined)
            return false;
        return model.length !== undefined ? model.length > 0 : true;
    }

    property bool menuOpen: false
    readonly property int innerRadius: 8
    readonly property int pressedInnerRadius: 4

    property bool fillWidth: false
    property bool leadingFillsWidth: false

    readonly property int segmentCount: model?.count ?? model?.length ?? 0
    readonly property real distributedSegmentWidth: segmentCount > 0 ? (width - (segmentCount - 1) * 2) / segmentCount : width

    readonly property int segmentHeight: 40

    readonly property bool mainHovered: mainHoverHandler.hovered
    readonly property bool mainPressed: mainTapHandler.pressed
    readonly property bool menuHovered: menuHoverHandler.hovered
    readonly property bool menuPressed: menuTapHandler.pressed

    signal clicked
    signal menuItemActivated(int index)

    function openMenu() {
        if (enabled && hasMenu)
            menu.open();
    }

    implicitHeight: segmentHeight
    implicitWidth: {
        let w = mainRow.implicitWidth + 32;
        if (hasMenu)
            w += 2 + menuRow.implicitWidth + 16;
        return w;
    }
    opacity: enabled ? 1 : 0.38

    Keys.onReturnPressed: event => {
        if (enabled) {
            clicked();
            event.accepted = true;
        }
    }

    Keys.onSpacePressed: event => {
        if (enabled) {
            clicked();
            event.accepted = true;
        }
    }

    DropdownMenu {
        id: menu

        anchorItem: root
        model: root.model
        onAboutToShow: root.menuOpen = true

        onAboutToHide: root.menuOpen = false
        textRole: root.textRole
        isItemEnabled: root.isItemEnabled
        disabledLabel: root.disabledLabel

        onActivated: index => {
            root.menuItemActivated(index);
            close();
        }
    }

    StyledRect {
        id: mainSegment

        x: 0
        width: {
            if (root.leadingFillsWidth)
                return root.width - (root.hasMenu ? 2 + menuSegment.width : 0);
            if (root.fillWidth)
                return root.distributedSegmentWidth;
            return root.hasMenu ? root.implicitWidth - 2 - menuSegment.width : root.implicitWidth;
        }
        height: root.segmentHeight
        activeFocusOnTab: root.enabled
        topLeftRadius: Appearance.rounding.full
        bottomLeftRadius: Appearance.rounding.full
        topRightRadius: root.mainPressed ? root.pressedInnerRadius : root.innerRadius
        bottomRightRadius: root.mainPressed ? root.pressedInnerRadius : root.innerRadius
        color: root.containerColor

        Behavior on topRightRadius {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.type: Easing.OutBack
            }
        }

        Behavior on bottomRightRadius {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.type: Easing.OutBack
            }
        }

        StyledRect {
            id: mainOverlay

            anchors.fill: parent
            topLeftRadius: parent.topLeftRadius
            bottomLeftRadius: parent.bottomLeftRadius
            topRightRadius: parent.topRightRadius
            bottomRightRadius: parent.bottomRightRadius
            color: root.contentColor
            opacity: root.mainHovered || root.mainPressed ? (root.mainPressed ? 0.12 : 0.08) : 0
        }

        Rectangle {
            anchors.fill: parent
            topLeftRadius: mainSegment.topLeftRadius
            bottomLeftRadius: mainSegment.bottomLeftRadius
            topRightRadius: mainSegment.topRightRadius
            bottomRightRadius: mainSegment.bottomRightRadius
            color: "transparent"
            border.color: Colours.m3Colors.m3Primary
            border.width: 2
            opacity: mainSegment.activeFocus ? 1 : 0
        }

        RowLayout {
            id: mainRow

            anchors.centerIn: parent
            spacing: 8

            Icon {
                visible: root.icon.name !== ""
                icon: root.icon.name
                color: root.contentColor
                font.pixelSize: Appearance.fonts.size.large * 1.2
            }

            StyledText {
                visible: root.text !== ""
                text: root.text
                color: root.contentColor
                font.pixelSize: root.textSize
                font.weight: Font.Medium
            }
        }

        HoverHandler {
            id: mainHoverHandler

            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            id: mainTapHandler

            enabled: root.enabled
            onTapped: root.clicked()
        }

        Keys.onReturnPressed: event => {
            if (root.enabled) {
                root.clicked();
                event.accepted = true;
            }
        }

        Keys.onSpacePressed: event => {
            if (root.enabled) {
                root.clicked();
                event.accepted = true;
            }
        }
    }

    StyledRect {
        id: menuSegment

        visible: root.hasMenu
        x: mainSegment.width + 2
        width: menuRow.implicitWidth + 16
        height: root.segmentHeight
        activeFocusOnTab: root.enabled
        topRightRadius: Appearance.rounding.full
        bottomRightRadius: Appearance.rounding.full
        topLeftRadius: root.innerRadius
        bottomLeftRadius: root.innerRadius
        color: root.containerColor

        // qmllint disable
        states: [
            State {
                name: "menu_open"
                when: root.menuOpen
                PropertyChanges {
                    target: menuSegment
                    topLeftRadius: root.segmentHeight * 0.5
                    bottomLeftRadius: root.segmentHeight * 0.5
                }
            },
            State {
                name: "menu_pressed"
                when: root.menuPressed
                PropertyChanges {
                    target: menuSegment
                    topLeftRadius: root.pressedInnerRadius
                    bottomLeftRadius: root.pressedInnerRadius
                }
            }
        ]
        // qmllint enable

        transitions: Transition {
            from: "*"
            to: "*"
            NAnim {
                properties: "topLeftRadius,bottomLeftRadius"
                duration: Appearance.animations.durations.normal
                easing.type: Easing.OutBack
            }
        }

        StyledRect {
            id: menuOverlay

            anchors.fill: parent
            topLeftRadius: parent.topLeftRadius
            bottomLeftRadius: parent.bottomLeftRadius
            topRightRadius: parent.topRightRadius
            bottomRightRadius: parent.bottomRightRadius
            color: root.contentColor
            opacity: root.menuHovered || root.menuPressed || root.menuOpen ? (root.menuPressed ? 0.12 : 0.08) : 0
        }

        Rectangle {
            anchors.fill: parent
            topLeftRadius: menuSegment.topLeftRadius
            bottomLeftRadius: menuSegment.bottomLeftRadius
            topRightRadius: menuSegment.topRightRadius
            bottomRightRadius: menuSegment.bottomRightRadius
            color: "transparent"
            border.color: Colours.m3Colors.m3Primary
            border.width: 2
            opacity: menuSegment.activeFocus ? 1 : 0
        }

        RowLayout {
            id: menuRow

            anchors.centerIn: parent
            spacing: 8

            Icon {
                icon: root.menuIcon.name
                color: root.menuIcon.color
                font.pixelSize: root.menuIcon.size
                rotation: root.menuOpen ? 180 : 0

                Behavior on rotation {
                    NAnim {}
                }
            }
        }

        HoverHandler {
            id: menuHoverHandler

            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            id: menuTapHandler

            enabled: root.enabled
            onTapped: root.openMenu()
        }

        Keys.onReturnPressed: event => {
            if (root.enabled) {
                root.openMenu();
                event.accepted = true;
            }
        }

        Keys.onSpacePressed: event => {
            if (root.enabled) {
                root.openMenu();
                event.accepted = true;
            }
        }
    }

    component IconComponent: QtObject {
        property color color: Colours.m3Colors.m3OnSecondaryContainer
        property string name: ""
        property int size: Appearance.fonts.size.large * 1.2
    }

    component MenuIconComponent: QtObject {
        property color color: Colours.m3Colors.m3OnSecondaryContainer
        property string name: "keyboard_arrow_down"
        property int size: Appearance.fonts.size.large * 1.2
    }
}
