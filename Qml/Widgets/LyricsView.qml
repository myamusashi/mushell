pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Lyrics
import Vast.Utils

import qs.Core.Configs
import qs.Services
import "../Components/Base"
import qs.Components.Base

Item {
    id: root

    property alias listView: listView
    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3Secondary
    property real activeFontSize: 22
    property real inactiveFontSize: 20

    ListView {
        id: listView

        anchors.fill: parent
        model: LyricsProvider.lines
        spacing: 16
        clip: true
        cacheBuffer: 0
        onCurrentIndexChanged: {
            if (currentIndex < 0)
                positionViewAtBeginning();
            else
                positionViewAtIndex(currentIndex, ListView.Center);
        }

        Binding {
            target: listView
            property: "currentIndex"
            value: LyricsProvider.currentLineIndex
        }

        Connections {
            target: Lyrics

            function onLinesChanged() {
                listView.positionViewAtBeginning();
            }
        }

        delegate: Column {
            id: lineDelegate

            required property var modelData
            required property int index
            readonly property bool isActiveLine: index === LyricsProvider.currentLineIndex

            width: listView.width
            spacing: 4

            scale: isActiveLine ? 1.0 : 0.9
            opacity: {
                if (!Lyrics.synced)
                    return 1.0;
                return isActiveLine ? 1.0 : 0.45;
            }

            Behavior on scale {
                NAnim {
                    duration: Math.max(200, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }
            Behavior on opacity {
                NAnim {
                    duration: Math.max(150, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }

            Flow {
                width: parent.width
                spacing: 0

                Repeater {
                    model: lineDelegate.modelData.text

                    delegate: StyledText {
                        id: flowText

                        required property var modelData
                        property color flashInFrom
                        property color flashInTo
                        property bool flashInActive: false
                        property real flashInBlend: 1.0

                        onFlashInBlendChanged: {
                            if (!flashInActive)
                                return;
                            if (flashInBlend >= 1) {
                                color = flashInTo;
                                flashInActive = false;
                            } else if (flashInBlend > 0) {
                                color = ColorUtils.blendColors(flashInFrom, flashInTo, flashInBlend);
                            }
                        }

                        NAnim {
                            id: flashInAnim
                            target: flowText
                            property: "flashInBlend"
                            from: 0.0
                            to: 1.0
                            duration: Math.max(150, LyricsProvider.currentWordDuration)
                            easing.bezierCurve: Appearance.animations.curves.emphasized
                        }

                        text: modelData
                        font {
                            pixelSize: Appearance.fonts.size.large
                            weight: Font.DemiBold
                            family: "Noto Sans"
                            hintingPreference: Font.PreferNoHinting
                            kerning: true
                            preferShaping: true
                        }
                        property color lyricTarget: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                        renderType: Text.QtRendering
                        style: Text.Raised
                        styleColor: Qt.alpha(Colours.m3Colors.m3Scrim, 0.5)

                        onLyricTargetChanged: {
                            flashInAnim.stop();
                            flashInFrom = flowText.color;
                            flashInTo = lyricTarget;
                            flashInActive = true;
                            flashInBlend = 0.0;
                            flashInAnim.start();
                        }
                    }
                }
            }

            StyledText {
                id: translationText
                property color flashOutFrom
                property color flashOutTo
                property bool flashOutActive: false
                property real flashOutBlend: 1.0

                onFlashOutBlendChanged: {
                    if (!flashOutActive)
                        return;
                    if (flashOutBlend >= 1) {
                        color = flashOutTo;
                        flashOutActive = false;
                    } else if (flashOutBlend > 0) {
                        color = ColorUtils.blendColors(flashOutFrom, flashOutTo, flashOutBlend);
                    }
                }

                NAnim {
                    id: flashOutAnim
                    target: translationText
                    property: "flashOutBlend"
                    from: 0.0
                    to: 1.0
                    duration: Math.max(150, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }

                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: `(${lineDelegate.modelData.translation})`
                visible: lineDelegate.modelData.translation !== ""
                font {
                    pixelSize: Appearance.fonts.size.normal
                    weight: Font.DemiBold
                    family: "Noto Sans"
                    hintingPreference: Font.PreferNoHinting
                    kerning: true
                    preferShaping: true
                }
                property color translationTarget: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                style: Text.Raised
                styleColor: Qt.alpha(Colours.m3Colors.m3Scrim, 0.5)
                opacity: 0.7

                onTranslationTargetChanged: {
                    flashOutAnim.stop();
                    flashOutFrom = translationText.color;
                    flashOutTo = translationTarget;
                    flashOutActive = true;
                    flashOutBlend = 0.0;
                    flashOutAnim.start();
                }
            }
        }
    }
}
