pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: root

    readonly property real horizontalPadding: Appearance.spacing.normal
    property real widgetHeight: 35

    implicitWidth: visible ? systemTrayRow.width + horizontalPadding * 1.2 : 0
    implicitHeight: widgetHeight
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

                    width: 25
                    height: 25
                    radius: Appearance.rounding.normal
                    color: trayItemArea.containsMouse ? Colours.m3Colors.m3Primary : "transparent"

                    Behavior on color {
                        CAnim {}
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    width: Appearance.fonts.size.large * 1.2
                    height: Appearance.fonts.size.large * 1.2
                    source: parent.iconSource
                    asynchronous: true

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
                            var validWindow = window;
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
                                menuAnchor.menu = delegateTray.modelData?.menu;
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
