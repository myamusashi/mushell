//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma DropExpensiveFonts

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Wayland

import qs.Components.Feedback
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import "Greeter" as GREET

ShellRoot {
    id: root

    WlSessionLock {
        id: lock
        locked: false

        GREET.Surface {
            lock: lock
            auth: authenticator
        }
    }

    GREET.Auth {
        id: authenticator
    }

    QtObject {
        id: rootFlow

        property bool introducing: true
        property bool launching: false
    }

    Connections {
        target: authenticator

        function onLaunchReady() {
            if (rootFlow.launching)
                return;
            rootFlow.launching = true;
            rootFlow.introducing = false;
            sessionTimer.restart();
        }
    }

    Connections {
        target: Greetd

        function onError() {
            sessionTimer.stop();
            rootFlow.launching = false;
        }
    }

    Timer {
        id: introduceTimer

        interval: 3000
        running: true

        onTriggered: {
            rootFlow.introducing = false;
            lock.locked = true;
        }
    }

    Timer {
        id: sessionTimer

        interval: 0

        onTriggered: authenticator.launch()
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: splashPanel

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            required property ShellScreen modelData

            readonly property bool splashVisible: rootFlow.introducing || (rootFlow.launching && !lock.locked)

            screen: modelData
            color: "transparent"
            contentItem.opacity: splashVisible ? 1 : 0

            Behavior on contentItem.opacity {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            Image {
                anchors.fill: parent
                onStatusChanged: {
                    if (status === Image.Error)
                        source = Paths.projectRoot + "/Assets/images/wallpaper.png";
                }
                source: "/etc/vast-shell/wallpaper.png"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            ColumnLayout {
                anchors.centerIn: parent
                anchors.margins: Appearance.margin.large
                spacing: Appearance.spacing.normal

                LoadingIndicator {
                    implicitWidth: 64
                    implicitHeight: 64
                    status: splashPanel.splashVisible
                }

                StyledText {
                    text: splashPanel.splashVisible && rootFlow.launching ? qsTr("Session Start") : "Loading..."
                    font.pixelSize: Appearance.fonts.size.extraLarge
                    color: Colours.m3Colors.m3OnSurface
                }
            }
        }
    }
}
