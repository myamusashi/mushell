pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "../Components/Base"
import qs.Components.Base

StyledRect {
    id: root

    property alias widgetHeight: root.implicitHeight
    readonly property real horizontalPadding: Appearance.spacing.normal

    implicitWidth: visible ? systemTrayRow.width + horizontalPadding * 1.2 : 0
    implicitHeight: 35
    radius: Appearance.rounding.small
    color: "transparent"
    visible: SystemTray.items.values.length > 0

    Behavior on implicitWidth {
        NAnim {}
    }

    Row {
        id: systemTrayRow

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Repeater {
            model: SystemTray.items.values
            delegate: Item {
                id: delegateTray

                required property SystemTrayItem modelData
                property string iconSource: {
                    let icon = modelData && modelData.icon;
                    if (typeof icon === 'string' || icon instanceof String) {
                        if (icon.includes("?path=")) {
                            const split = icon.split("?path=");
                            if (split.length !== 2)
                                return icon;
                            const name = split[0];
                            const path = split[1];
                            const fileName = name.substring(name.lastIndexOf("/") + 1);
                            return "file://" + path + "/" + fileName;
                        }
                        return icon;
                    }
                    return "";
                }

                width: 25
                height: 25

                StyledRect {
                    id: bgTrayIcon
                    property color target: trayItemArea.containsMouse ? Colours.m3Colors.m3Primary : "transparent"
                    property color cFrom
                    property color cTo
                    property bool cActive: false
                    property real cBlend: 1.0
                    onCBlendChanged: {
                        if (!cActive)
                            return;
                        if (cBlend >= 1) {
                            color = cTo;
                            cActive = false;
                        } else if (cBlend > 0) {
                            color = Colours.blendColors(cFrom, cTo, cBlend);
                        }
                    }
                    onTargetChanged: {
                        cAnim.stop();
                        cFrom = color;
                        cTo = target;
                        cActive = true;
                        cBlend = 0.0;
                        cAnim.start();
                    }

                    width: 25
                    height: 25
                    radius: Appearance.rounding.normal

                    NAnim {
                        id: cAnim
                        target: bgTrayIcon
                        property: "cBlend"
                        from: 0.0
                        to: 1.0
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    width: Appearance.fonts.size.large * 1.2
                    height: Appearance.fonts.size.large * 1.2
                    source: parent.iconSource
                    asynchronous: true
                    backer.cache: true
                    smooth: true
                    mipmap: true
                }

                MArea {
                    id: trayItemArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (!delegateTray.modelData)
                            return;
                        if (mouse.button === Qt.LeftButton && !delegateTray.modelData.onlyMenu) {
                            delegateTray.modelData.activate();
                            return;
                        }

                        if (delegateTray.modelData.hasMenu) {
                            var validWindow = window; // qmllint disable
                            if (!validWindow) {
                                var item = root.parent;
                                while (item && !validWindow) {
                                    if (item.toString().includes("WlrLayershell")) {
                                        validWindow = item;
                                        break;
                                    }
                                    item = item.parent;
                                }
                            }

                            if (validWindow) {
                                menuAnchor.menu = delegateTray.modelData?.menu; // qmllint disable
                                menuAnchor.anchor.window = validWindow;
                                menuAnchor.anchor.rect = validWindow.mapFromItem(delegateTray, 0, delegateTray.height, delegateTray.width, delegateTray.width);
                                menuAnchor.open();
                            } else {
                                console.warn("Cannot find valid Quickshell window for tray menu");
                            }
                        }
                    }
                }
            }
        }
    }

    QsMenuAnchor {
        id: menuAnchor
    }
}
