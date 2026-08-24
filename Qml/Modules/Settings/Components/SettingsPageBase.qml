pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Services
import qs.Core.Configs
import qs.Components.Base
import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    default property alias content: contentLayout.data
    property string pageTitle

    CardRevealer {
        id: cardRevealer

        container: contentLayout
        target: pageFlickable
    }

    function revealCard(cardTitle: string): bool {
        return cardRevealer.reveal(cardTitle);
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.margin.large
        }
        spacing: Appearance.spacing.large

        StyledText {
            text: root.pageTitle
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Appearance.margin.normal
        }

        Flickable {
            id: pageFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: contentLayout.implicitHeight
            interactive: contentHeight > height

            ColumnLayout {
                id: contentLayout
                width: parent.width
                spacing: Appearance.spacing.large
            }
        }
    }
}
