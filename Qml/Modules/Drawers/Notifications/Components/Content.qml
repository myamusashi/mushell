pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Components.Button
import qs.Services

Column {
    id: root

    required property var modelData
    property bool isShowMoreBody: false
    readonly property bool replyFocused: replyField.isFocused

    function syncInlineReplyFocus(): void {
        const hasReply = root.modelData?.hasInlineReply ?? false;
        if (root.replyFocused && hasReply)
            GlobalStates.inlineReplyOwner = root;
        else if (GlobalStates.inlineReplyOwner === root)
            GlobalStates.inlineReplyOwner = null;
    }

    onReplyFocusedChanged: syncInlineReplyFocus()
    onModelDataChanged: syncInlineReplyFocus()

    Component.onDestruction: {
        if (GlobalStates.inlineReplyOwner === root)
            GlobalStates.inlineReplyOwner = null;
    }

    function sendReply() {
        const text = replyField.text.trim();

        if (text === "")
            return;

        modelData.sendInlineReply(text);
        replyField.text = "";
    }

    spacing: Appearance.spacing.small

    RowLayout {
        width: parent.width
        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: root.modelData.appName
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnSurfaceVariant
            elide: Text.ElideRight
        }

        StyledText {
            text: "•"
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            Layout.preferredWidth: implicitWidth
        }

        StyledText {
            id: timeText

            color: Colours.m3Colors.m3OnSurfaceVariant
            Layout.preferredWidth: implicitWidth
            Component.onCompleted: text = TimeAgo.timeAgoWithIfElse(root.modelData.time)

            Timer {
                interval: 60000
                running: root.visible
                repeat: true
                onTriggered: timeText.text = TimeAgo.timeAgoWithIfElse(root.modelData.time)
            }
        }

        FloatingButton {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            backgroundRadius: Appearance.rounding.large
            icon.name: root.isShowMoreBody ? "expand_less" : "expand_more"
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            icon.size: Appearance.fonts.size.extraLarge
            color: "transparent"
            onClicked: root.isShowMoreBody = !root.isShowMoreBody
        }
    }

    StyledText {
        width: parent.width
        text: root.modelData.summary
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        color: Colours.m3Colors.m3OnSurface
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }

    StyledText {
        width: parent.width
        text: root.modelData.body || ""
        font.pixelSize: Appearance.fonts.size.medium
        color: Colours.m3Colors.m3OnSurface
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: root.isShowMoreBody ? 0 : 1
    }

    Row {
        width: parent.width
        topPadding: 8
        spacing: Appearance.spacing.normal
        visible: root.modelData?.actions && root.modelData.actions.length > 0

        Repeater {
            model: root.modelData?.actions

            delegate: StyledRect {
                id: actionButton

                required property var modelData
                required property int index

                implicitWidth: (parent.width - (root.modelData.actions.length - 1) * Appearance.spacing.normal) / root.modelData.actions.length
                implicitHeight: 40
                radius: Appearance.rounding.full
                color: Colours.m3Colors.m3SurfaceContainerHigh

                MArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: actionButton.modelData.invoke()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: actionButton.modelData.text
                    font.pixelSize: Appearance.fonts.size.medium
                    font.weight: Font.Medium
                    color: Colours.m3Colors.m3OnBackground
                    elide: Text.ElideRight
                }
            }
        }
    }

    RowLayout {
        width: parent.width
        spacing: Appearance.spacing.normal
        visible: root.modelData.hasInlineReply

        StyledTextInput {
            id: replyField

            Layout.fillWidth: true
            Layout.preferredHeight: 40
            toggleButtonVisible: false
            autoFocus: false
            placeHolderText: root.modelData.inlineReplyPlaceholder !== "" ? root.modelData.inlineReplyPlaceholder : qsTr("Reply…")
            onAccepted: root.sendReply()
            onKeyPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    root.forceActiveFocus();
                }
            }
        }

        FloatingButton {
            id: sendButton

            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            backgroundRadius: Appearance.rounding.full
            icon.name: "send"
            icon.color: Qt.alpha(Colours.m3Colors.m3OnBackground, replyField.hasText ? 1 : 0.4)
            icon.size: Appearance.fonts.size.extraLarge
            color: Colours.m3Colors.m3SurfaceContainerHigh
            onClicked: {
                if (replyField.hasText)
                    root.sendReply();
            }
        }
    }
}
