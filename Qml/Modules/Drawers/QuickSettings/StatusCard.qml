pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: card

    default property alias content: contentLayout.data
    required property string title
    required property var zoomId
    required property Item zoomTarget
    property bool isTopLeft: false
    property bool isTopRight: false
    property bool isBottomLeft: false
    property bool isBottomRight: false

    Layout.fillWidth: true
    Layout.preferredHeight: 150
    radius: Appearance.rounding.small * 0.5
    clip: true

    topLeftRadius: isTopLeft ? Appearance.rounding.normal : radius
    topRightRadius: isTopRight ? Appearance.rounding.normal : radius
    bottomLeftRadius: isBottomLeft ? Appearance.rounding.normal : radius
    bottomRightRadius: isBottomRight ? Appearance.rounding.normal : radius

    color: Colours.m3Colors.m3SurfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        spacing: Appearance.spacing.small

        StyledText {
            text: card.title
            color: Colours.m3Colors.m3Green
            font.pixelSize: Appearance.fonts.size.large
        }

        ColumnLayout {
            id: contentLayout

            Layout.fillWidth: true
            spacing: Appearance.spacing.small
        }
    }

    MArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        layerRadius: card.isTopLeft ? card.topLeftRadius : card.isTopRight ? card.topRightRadius : card.isBottomRight ? card.bottomRightRadius : card.isBottomLeft ? card.bottomLeftRadius : card.radius
        onClicked: {
            var cardCenter = card.mapToItem(card.zoomTarget, card.width / 2, card.height / 2);
            card.zoomId.zoomOriginX = cardCenter.x;
            card.zoomId.zoomOriginY = cardCenter.y;
            card.zoomId.isVisible = true;
        }
    }
}
