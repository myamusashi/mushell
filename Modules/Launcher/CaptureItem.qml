import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: root

    property var optionData
    property int optionIndex
    property bool isSelected
    property int maxIndex

    signal executed
    signal indexModel(int newIndex)
    signal closed

    focus: root.isSelected

    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.executeAction();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            root.closed();
            event.accepted = true;
            break;
        case Qt.Key_Up:
            if (root.optionIndex > 0)
                root.indexModel(root.optionIndex - 1);
            event.accepted = true;
            break;
        case Qt.Key_Down:
            if (root.optionIndex < root.maxIndex)
                root.indexModel(root.optionIndex + 1);
            event.accepted = true;
            break;
        }
    }

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing.small
        anchors.rightMargin: Appearance.spacing.small
        spacing: Appearance.spacing.normal

        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2
            xScale: root.isSelected ? 1.03 : 1.0
            yScale: root.isSelected ? 1.03 : 1.0

            Behavior on xScale {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on yScale {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        MaterialIcon {
            icon: root.optionData.icon
            color: root.isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Outline
            font.pixelSize: Appearance.fonts.size.large
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                CAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        StyledText {
            color: root.isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Outline
            font.pixelSize: Appearance.fonts.size.normal
            text: root.optionData.name
            Layout.fillWidth: true
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.executeAction()
        onEntered: root.forceActiveFocus()
    }

    function executeAction() {
        root.forceActiveFocus();
        root.optionData.action();
        root.executed();
    }
}
