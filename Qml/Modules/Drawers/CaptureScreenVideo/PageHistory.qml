pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services.CaptureScreenVideo

StyledRect {
    id: root

    signal goBack
    signal openFile(string path)

    color: "transparent"
    radius: 0
    clip: true

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.small

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
            color: "transparent"
            radius: Appearance.rounding.small

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.spacing.small
                }
                spacing: Appearance.spacing.small

                Icon {
                    type: Icon.Material
                    icon: "arrow_back"
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                }

                StyledText {
                    text: qsTr("Recordings")
                    color: Colours.m3Colors.m3OnSurface
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            MArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.goBack()
            }
        }

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacing.small
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            focus: true

            model: ScriptModel {
                values: [...ScreenCaptureHistory.screenrecordFiles]
            }

            delegate: StyledRect {
                id: delegateRoot

                required property var modelData
                required property int index

                readonly property string fileExt: {
                    const fn = modelData.path.split("/").pop();
                    const dot = fn.lastIndexOf(".");
                    return dot > 0 ? fn.substring(dot + 1).toLowerCase() : "";
                }

                width: listView.width
                height: 56
                color: listView.currentIndex === index ? Qt.alpha(Colours.m3Colors.m3Primary, 0.15) : (delegateMouse.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                radius: Appearance.rounding.small

                Component.onCompleted: CaptureScreenVideo.createThumbnail(modelData.path, Paths.cacheDir + "/video-thumbnails")

                Connections {
                    target: CaptureScreenVideo
                    function onThumbnailReady(videoPath, thumbnailPath) {
                        if (videoPath !== delegateRoot.modelData.path)
                            return;
                        thumbLoader.thumbPath = thumbnailPath ? "file://" + thumbnailPath : "";
                    }
                }

                property alias thumbLoader: thumbLoader

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.margin.small
                    spacing: Appearance.spacing.small

                    Loader {
                        id: thumbLoader

                        property string thumbPath: ""

                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignVCenter

                        sourceComponent: StyledRect {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: Appearance.rounding.small
                            color: Colours.m3Colors.m3PrimaryContainer

                            Image {
                                id: thumbImage
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectCrop
                                cache: true
                                asynchronous: true
                                width: 40
                                height: 40
                                sourceSize: Qt.size(40, 40)
                                source: thumbLoader.thumbPath
                            }

                            Icon {
                                anchors.centerIn: parent
                                type: Icon.Material
                                icon: "play_circle"
                                color: Colours.m3Colors.m3OnPrimaryContainer
                                font.pixelSize: 20
                                visible: thumbImage.status !== Image.Ready && thumbImage.status !== Image.Loading
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        StyledText {
                            text: delegateRoot.modelData.name
                            color: listView.currentIndex === delegateRoot.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: {
                                const ts = delegateRoot.modelData.created;
                                const d = new Date(ts * 1000);
                                return d.toLocaleString("en-US", {
                                    month: "short",
                                    day: "numeric",
                                    hour: "numeric",
                                    minute: "2-digit"
                                });
                            }
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.small
                        }
                    }

                    Icon {
                        type: Icon.Material
                        icon: "open_in_new"
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                        Layout.alignment: Qt.AlignVCenter

                        MArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openFile(delegateRoot.modelData.path)
                        }
                    }
                }

                MArea {
                    id: delegateMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        listView.currentIndex = delegateRoot.index;
                        root.openFile(delegateRoot.modelData.path);
                    }
                }
            }

            Keys.onReturnPressed: {
                const item = listView.model.get ? listView.model.get(listView.currentIndex) : listView.model[listView.currentIndex];
                if (item)
                    root.openFile(item.path);
            }

            Keys.onUpPressed: {
                if (listView.currentIndex > 0)
                    listView.currentIndex--;
            }

            Keys.onDownPressed: {
                if (listView.currentIndex < listView.count - 1)
                    listView.currentIndex++;
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }
}
