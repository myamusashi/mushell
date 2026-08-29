pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Clipboard
import Vast.Utils

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base

Item {
    id: root

    required property var entryList
    required property var uiState
    required property int currentId

    property alias searchField: searchField

    signal keyPressed(var event)

    implicitHeight: 48

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.large
        anchors.rightMargin: Appearance.margin.large
        anchors.topMargin: Appearance.margin.smaller
        anchors.bottomMargin: Appearance.margin.smaller
        spacing: Appearance.spacing.smaller

        Icon {
            id: searchIcon

            property color target: searchField.isFocused ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            property color colorFrom
            property color colorTo
            property bool colorBlending: false
            property real colorBlendProgress: 1.0

            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }

            onTargetChanged: {
                colorBlendAnim.stop();
                colorFrom = color;
                colorTo = target;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim.start();
            }

            icon: "search"
            font.pixelSize: Appearance.fonts.size.larger

            NAnim {
                id: colorBlendAnim

                target: searchIcon
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
            }
        }

        StyledTextInput {
            id: searchField

            Layout.fillWidth: true
            Layout.preferredHeight: 35
            autoFocus: !Configs.clipboard.enableVimKeybinds
            placeHolderText: qsTr("Search clipboard…")
            toggleButtonVisible: false

            Timer {
                id: searchDebounce

                interval: 150
                repeat: false
                onTriggered: ClipboardManager.model.setFilter(searchField.text)
            }

            onTextChanged: {
                if (text.length === 0) {
                    searchDebounce.stop();
                    ClipboardManager.model.setFilter("");
                } else {
                    searchDebounce.restart();
                }
            }

            onAccepted: {
                if (Configs.clipboard.enableVimKeybinds && !searchField.isFocused) {
                    return;
                }
                if (root.currentId >= 0) {
                    ClipboardManager.copyToClipboard(root.currentId);
                    if (!Configs.clipboard.keepOpenAfterCopy)
                        GlobalStates.isClipboardOpen = false;
                }
            }

            onKeyPressed: event => root.keyPressed(event)
        }

        StyledText {
            text: (root.entryList.currentPage + 1) + " / " + root.entryList.totalPages
            font.pixelSize: Appearance.fonts.size.small
            color: Colours.m3Colors.m3OnSurfaceVariant
            visible: root.entryList.totalPages > 0 && searchField.text.length === 0 && !root.uiState.visualActive
        }

        StyledText {
            text: qsTr("VISUAL") + " " + root.entryList.visualSelectableCount
            font.pixelSize: Appearance.fonts.size.small
            font.bold: true
            color: Colours.m3Colors.m3Primary
            visible: root.uiState.visualActive
        }
    }
}
