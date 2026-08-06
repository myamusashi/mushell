pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Lyrics

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
                        property color c0From
                        property color c0To
                        property bool c0Active: false
                        property real c0Blend: 1.0

                        onC0BlendChanged: {
                            if (!c0Active)
                                return;
                            if (c0Blend >= 1) {
                                color = c0To;
                                c0Active = false;
                            } else if (c0Blend > 0) {
                                color = Colours.blendColors(c0From, c0To, c0Blend);
                            }
                        }

                        NAnim {
                            id: c0Anim
                            target: flowText
                            property: "c0Blend"
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
                        styleColor: "#80000000"

                        onLyricTargetChanged: {
                            c0Anim.stop();
                            c0From = flowText.color;
                            c0To = lyricTarget;
                            c0Active = true;
                            c0Blend = 0.0;
                            c0Anim.start();
                        }
                    }
                }
            }

            StyledText {
                id: translationText
                property color c1From
                property color c1To
                property bool c1Active: false
                property real c1Blend: 1.0

                onC1BlendChanged: {
                    if (!c1Active)
                        return;
                    if (c1Blend >= 1) {
                        color = c1To;
                        c1Active = false;
                    } else if (c1Blend > 0) {
                        color = Colours.blendColors(c1From, c1To, c1Blend);
                    }
                }

                NAnim {
                    id: c1Anim
                    target: translationText
                    property: "c1Blend"
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
                property color transTarget: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                style: Text.Raised
                styleColor: "#80000000"
                opacity: 0.7

                onTransTargetChanged: {
                    c1Anim.stop();
                    c1From = translationText.color;
                    c1To = transTarget;
                    c1Active = true;
                    c1Blend = 0.0;
                    c1Anim.start();
                }
            }
        }
    }
}
