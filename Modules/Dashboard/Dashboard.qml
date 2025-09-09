pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications

import qs.Data
import qs.Helpers
import qs.Widgets
import qs.Components

Scope {
	id: root

	property bool isDashboardOpen: false
	property int currentIndex: 0
	property int baseWidth: 1366
	property int baseHeight: 768
	property int baseSectionWidth: 455
	property int baseSectionHeight: baseWidth
	property int cpuUsage: 0
	property int ramUsage: 0

	function toggleDashboard(): void {
		isDashboardOpen = !isDashboardOpen;
	}

	PanelWindow {
		id: dashboard

		property ShellScreen modelData

		anchors {
			top: true
			bottom: true
			right: true
			left: true
		}

		WlrLayershell.namespace: "shell"
		visible: root.isDashboardOpen
		focusable: true
		color: "transparent"
		screen: modelData
		exclusiveZone: 0
		implicitWidth: root.baseWidth
		implicitHeight: root.baseHeight

		Rectangle {
			anchors.fill: parent
			anchors.margins: 20
			color: "transparent"

			Item {
				anchors.fill: parent
				focus: true
				Keys.onEscapePressed: root.toggleDashboard()

				RowLayout {
					anchors.fill: parent
					spacing: Appearance.spacing.large

					ColumnLayout {
						id: notifsAndWeatherLayout

						Layout.fillWidth: true
						Layout.alignment: Qt.AlignTop
						Layout.maximumHeight: parent.height
						Layout.preferredWidth: root.baseWidth / 3
						Layout.minimumWidth: 400

						Rectangle {
							Layout.fillWidth: true
							Layout.preferredHeight: 60
							color: Appearance.colors.surface
							radius: 8
							border.color: Appearance.colors.outline
							border.width: 2

							RowLayout {
								anchors.fill: parent
								anchors.margins: 16

								Text {
									Layout.fillWidth: true
									text: "Notifications"
									color: Appearance.colors.on_background
									font.pixelSize: Appearance.fonts.large * 1.2
									font.weight: Font.Medium
								}

								Repeater {
									model: [
										{
											icon: "clear_all",
											action: () => {
												Notifs.notifications.dismissAll();
											}
										},
										{
											icon: Notifs.notifications.isDnDDisabled ? "notifications_active" : "notifications_off",
											action: () => {
												Notifs.notifications.isDnDDisabled = !Notifs.notifications.isDnDDisabled;
											}
										}
									]

									delegate: Rectangle {
										id: notifHeaderDelegate

										Layout.preferredWidth: 32
										Layout.preferredHeight: 32
										radius: 6
										color: iconMouse.containsMouse ? Appearance.colors.surface_container_high : "transparent"

										required property var modelData

										MatIcon {
											anchors.centerIn: parent
											icon: notifHeaderDelegate.modelData.icon
											font.pixelSize: Appearance.fonts.large * 1.6
											color: Appearance.colors.on_background
										}

										MouseArea {
											id: iconMouse

											anchors.fill: parent
											cursorShape: Qt.PointingHandCursor
											hoverEnabled: true
											onClicked: notifHeaderDelegate.modelData.action()
										}
									}
								}
							}
						}

						Rectangle {
							Layout.fillWidth: true
							Layout.fillHeight: true
							color: Appearance.colors.surface
							radius: 8
							border.color: Appearance.colors.outline
							border.width: 1

							ScrollView {
								anchors.fill: parent
								anchors.margins: 16
								clip: true

								// Lmao just copy the code from Notifications.qml
								ListView {
									id: listViewNotifs

									spacing: 8
									model: ScriptModel {
										values: [...Notifs.notifications.listNotifications.map(a => a)].reverse()
									}

									delegate: Rectangle {
										id: rectDelegate

										required property Notification modelData

										property bool hasImage: modelData.image.length > 0
										property bool hasAppIcon: modelData.appIcon.length > 0

										width: listViewNotifs.width
										height: Math.max(80, contentLayout.implicitHeight + 16)
										color: Appearance.colors.surface_container
										radius: 6

										RetainableLock {
											object: rectDelegate.modelData
											locked: true
										}

										RowLayout {
											id: contentLayout

											anchors.fill: parent
											anchors.margins: 8
											Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
											spacing: 8

											Loader {
												id: image

												active: rectDelegate.hasImage
												asynchronous: true

												anchors.left: parent.left
												anchors.top: parent.top
												width: 80
												height: 80
												visible: rectDelegate.hasImage || rectDelegate.hasAppIcon

												sourceComponent: ClippingRectangle {
													radius: Appearance.rounding.full
													implicitWidth: 80
													implicitHeight: 80

													Image {
														anchors.fill: parent
														source: Qt.resolvedUrl(rectDelegate.modelData.image)
														fillMode: Image.PreserveAspectCrop
														cache: false
														asynchronous: true
													}
												}
											}

											// Thank you Caelestia
											Loader {
												id: appIcon

												active: rectDelegate.hasAppIcon || !rectDelegate.hasImage
												asynchronous: true

												anchors.horizontalCenter: rectDelegate.hasImage ? undefined : image.horizontalCenter
												anchors.verticalCenter: rectDelegate.hasImage ? undefined : image.verticalCenter
												anchors.right: rectDelegate.hasImage ? image.right : undefined
												anchors.bottom: rectDelegate.hasImage ? image.bottom : undefined

												sourceComponent: Rectangle {
													radius: Appearance.rounding.full
													color: rectDelegate.modelData.urgency === NotificationUrgency.Critical ? Appearance.colors.error : rectDelegate.modelData.urgency === NotificationUrgency.Low ? Appearance.colors.surface_container_highest : Appearance.colors.secondary_container

													Loader {
														id: icon

														active: rectDelegate.hasAppIcon
														asynchronous: true

														anchors.centerIn: parent

														width: 80
														height: 80

														sourceComponent: IconImage {
															anchors.fill: parent
															source: Quickshell.iconPath(rectDelegate.modelData.appIcon)
														}
													}

													Loader {
														active: !rectDelegate.hasAppIcon
														asynchronous: true
														anchors.centerIn: parent
														anchors.horizontalCenterOffset: -Appearance.fonts.large * 0.02
														anchors.verticalCenterOffset: Appearance.fonts.large * 0.02

														sourceComponent: MatIcon {
															text: "release_alert"

															color: rectDelegate.modelData.urgency === NotificationUrgency.Critical ? Appearance.colors.on_error : rectDelegate.modelData.urgency === NotificationUrgency.Low ? Appearance.colors.on_surface : Appearance.colors.on_secondary_container
															font.pointSize: Appearance.fonts.large
														}
													}
												}
											}

											ColumnLayout {
												Layout.fillWidth: true
												spacing: 4

												RowLayout {
													Layout.fillWidth: true

													Text {
														id: appName
														Layout.fillWidth: true
														text: rectDelegate.modelData.appName
														font.pixelSize: Appearance.fonts.small * 0.9
														color: Appearance.colors.on_background
														elide: Text.ElideRight
													}

													MatIcon {
														icon: "close"
														font.pixelSize: Appearance.fonts.large * 1.8
														color: mIcon.containsMouse ? Appearance.colors.withAlpha(Appearance.colors.error, 0.4) : Appearance.colors.error

														MouseArea {
															id: mIcon
															anchors.fill: parent
															hoverEnabled: true

															onClicked: mevent => {
																if (mevent.button === Qt.LeftButton) {
																	Notifs.notifications.removeListNotification(rectDelegate.modelData);
																}
															}
														}
													}
												}

												Text {
													id: summary

													Layout.fillWidth: true
													text: rectDelegate.modelData.summary
													font.pixelSize: Appearance.fonts.normal
													color: Appearance.colors.on_background
													font.bold: true
													elide: Text.ElideRight
													wrapMode: Text.WordWrap
												}

												Text {
													id: body

													Layout.fillWidth: true
													text: rectDelegate.modelData.body || ""
													font.pixelSize: Appearance.fonts.small * 1.2
													color: Appearance.colors.on_background
													textFormat: Text.MarkdownText
													Layout.preferredWidth: parent.width
													wrapMode: Text.WrapAtWordBoundaryOrAnywhere
													visible: text.length > 0
												}

												RowLayout {
													Layout.topMargin: 8
													spacing: 8
													visible: rectDelegate.modelData?.actions && rectDelegate.modelData.actions.length > 0

													Repeater {
														model: rectDelegate.modelData?.actions

														delegate: Rectangle {
															id: actionButton

															Layout.fillWidth: true
															Layout.preferredHeight: 36

															required property NotificationAction modelData

															color: actionMouse.pressed ? Appearance.colors.primary_container : actionMouse.containsMouse ? Appearance.colors.surface_container_highest : Appearance.colors.surface_container_high

															border.color: actionMouse.containsMouse ? Appearance.colors.primary : Appearance.colors.outline
															border.width: actionMouse.containsMouse ? 2 : 1
															radius: 6

															Rectangle {
																anchors.fill: parent
																anchors.topMargin: 1
																color: "transparent"
																border.color: Appearance.colors.withAlpha(Appearance.colors.background, 0.01)
																border.width: actionMouse.pressed ? 0 : 1
																radius: parent.radius
																visible: !actionMouse.pressed
															}

															MouseArea {
																id: actionMouse
																anchors.fill: parent
																hoverEnabled: true
																cursorShape: Qt.PointingHandCursor

																onClicked: {
																	actionButton.modelData.invoke();
																}

																Rectangle {
																	id: ripple
																	anchors.centerIn: parent
																	width: 0
																	height: 0
																	radius: width / 2
																	color: Appearance.colors.withAlpha(Appearance.colors.primary, 0.3)
																	visible: false

																	SequentialAnimation {
																		id: rippleAnimation
																		PropertyAnimation {
																			target: ripple
																			property: "width"
																			to: Math.max(actionButton.width, actionButton.height) * 2
																			duration: Appearance.animations.durations.normal * 1.2
																			easing.type: Easing.BezierSpline
																			easing.bezierCurve: Appearance.animations.curves.standard
																		}
																		PropertyAnimation {
																			target: ripple
																			property: "height"
																			to: ripple.width
																			duration: 0
																		}
																		PropertyAnimation {
																			target: ripple
																			property: "opacity"
																			to: 0
																			duration: 200
																		}
																		onStarted: {
																			ripple.visible = true;
																			ripple.opacity = 1;
																		}
																		onFinished: {
																			ripple.visible = false;
																			ripple.width = 0;
																			ripple.height = 0;
																		}
																	}

																	Component.onCompleted: {
																		actionMouse.clicked.connect(rippleAnimation.start);
																	}
																}
															}

															Text {
																id: actionText
																anchors.centerIn: parent
																text: actionButton.modelData.text
																font.pixelSize: Appearance.fonts.small * 1.1
																font.weight: actionMouse.containsMouse ? Font.Medium : Font.Normal
																color: actionMouse.containsMouse ? Appearance.colors.on_primary_container : Appearance.colors.on_surface
																elide: Text.ElideRight
															}

															Behavior on color {
																ColorAnimation {
																	duration: Appearance.animations.durations.small
																}
															}
															Behavior on border.color {
																ColorAnimation {
																	duration: Appearance.animations.durations.small
																}
															}
															Behavior on border.width {
																NumberAnimation {
																	duration: Appearance.animations.durations.small
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
						WeatherWidget {
							Layout.fillWidth: true
							Layout.preferredHeight: 350
							Layout.topMargin: 8
						}
					}
					ColumnLayout {
						id: performanceLayout

						Layout.fillWidth: true
						Layout.fillHeight: true

						Layout.preferredWidth: root.baseWidth / 3
						Layout.minimumWidth: 400

						Rectangle {
							Layout.fillWidth: true
							Layout.fillHeight: true
							radius: 8
							color: "transparent"
							// border.color: Appearance.colors.outline
							// border.width: 2

							// ColumnLayout {
							// 	anchors.fill: parent
							// 	Rectangle {
							// 		id: ram
							// 		Layout.alignment: Qt.AlignTop | Qt.AlignVCenter
							//
							// 		Circular {
							// 			id: ramProgress
							//
							// 			width: 250
							// 			height: 250
							//
							// 			x: 50
							// 			y: 50
							// 			value: SysUsage.memUsed / SysUsage.memTotal
							//
							// 			backgroundColor: Appearance.colors.on_primary
							// 			progressColor: Appearance.colors.primary
							// 			strokeWidth: 15
							// 		}
							// 	}
							// 	Rectangle {
							// 		Layout.alignment: Qt.AlignBottom | Qt.AlignVCenter
							//
							// 		Circular {
							// 			id: cpuProgress
							//
							// 			width: 250
							// 			height: 250
							//
							// 			x: 50
							// 			y: 50
							// 			value: SysUsage.cpuPerc
							//
							// 			backgroundColor: Appearance.colors.on_primary
							// 			progressColor: Appearance.colors.primary
							// 			strokeWidth: 15
							// 		}
							// 	}
							// }
						}
					}

					ColumnLayout {
						id: mprisLayout

						Layout.fillWidth: true
						Layout.fillHeight: true
						Layout.preferredWidth: root.baseWidth / 3
						Layout.minimumWidth: 400

						Rectangle {
							Layout.fillWidth: true
							Layout.fillHeight: true
							radius: 8
							color: Appearance.colors.background
							border.color: Appearance.colors.outline
							border.width: 2

							ColumnLayout {
								anchors.fill: parent

								Repeater {
									model: Mpris.players

									Item {
										id: mprisControll

										anchors.fill: parent

										required property int index
										readonly property MprisPlayer player: Mpris.players.values[index]

										Rectangle {
											anchors.fill: parent
											color: "transparent"

											Column {
												anchors.horizontalCenter: parent.horizontalCenter
												anchors.top: parent.top
												anchors.topMargin: 60
												spacing: 20

												Item {
													id: coverContainer
													width: 250
													height: 250

													Image {
														id: cover
														anchors.fill: parent
														visible: false
														source: mprisControll.player.trackArtUrl || Qt.resolvedUrl(`${Quickshell.shellDir}/Assets/image_not_found.svg`)
														fillMode: Image.PreserveAspectCrop
														mipmap: true
													}

													MultiEffect {
														source: cover
														anchors.fill: parent
														maskEnabled: true
														maskSource: maskCover
													}

													Item {
														id: maskCover
														anchors.fill: parent
														layer.enabled: true
														visible: false
														Rectangle {
															anchors.fill: parent
															radius: width / 2
														}
													}
												}

												Column {
													anchors.horizontalCenter: parent.horizontalCenter
													spacing: 8

													Text {
														id: titleText
														anchors.horizontalCenter: parent.horizontalCenter
														text: mprisControll.player.trackTitle
														color: Appearance.colors.on_background
														font.pixelSize: Appearance.fonts.extraLarge
														font.bold: true
														horizontalAlignment: Text.AlignHCenter
														wrapMode: Text.WordWrap
														width: Math.min(implicitWidth, 300)
													}

													Text {
														id: artistText
														anchors.horizontalCenter: parent.horizontalCenter
														text: mprisControll.player.trackArtist
														color: Appearance.colors.on_background
														font.pixelSize: Appearance.fonts.large
														opacity: 0.8
														horizontalAlignment: Text.AlignHCenter
														wrapMode: Text.WordWrap
														width: Math.min(implicitWidth, 300)
													}
												}

												Row {
													anchors.horizontalCenter: parent.horizontalCenter
													spacing: 16

													Repeater {
														model: [
															{
																icon: "skip_previous",
																action: () => {
																	if (!mprisControll.player.canGoPrevious) {
																		console.log("Can't go back");
																		return;
																	}
																	mprisControll.player?.previous();
																}
															},
															{
																icon: mprisControll.player.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle",
																action: () => {
																	mprisControll.player.togglePlaying();
																}
															},
															{
																icon: "skip_next",
																action: () => {
																	mprisControll.player.next();
																}
															}
														]

														delegate: Item {
															id: delegateController

															required property var modelData
															width: 56
															height: 56

															Rectangle {
																id: bgCon
																anchors.fill: parent
																anchors.margins: 4
																color: Appearance.colors.primary
																radius: Appearance.rounding.small
																opacity: clickArea.containsMouse ? 1 : 0.7
																scale: clickArea.pressed ? 0.95 : 1.0

																Behavior on opacity {
																	NumberAnimation {
																		duration: 150
																	}
																}

																Behavior on scale {
																	NumberAnimation {
																		duration: 100
																	}
																}
															}

															MouseArea {
																id: clickArea
																anchors.fill: parent
																cursorShape: Qt.PointingHandCursor
																hoverEnabled: true
																onClicked: delegateController.modelData.action()
															}

															MatIcon {
																anchors.centerIn: parent
																color: Appearance.colors.on_primary
																font.pixelSize: Appearance.fonts.large * 1.5
																icon: delegateController.modelData.icon
															}
														}
													}
													Column {
														anchors.horizontalCenter: parent.horizontalCenter

														Slider {
															id: trackProgress

															anchors.centerIn: parent

															width: 300
															from: 0
															to: 100
															value: mprisControll.player.length

															onMoved: {
																const active = mprisControll.player.playbackState == MprisPlaybackState.Playing

															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

	IpcHandler {
		target: "dashboard"

		function toggle(): void {
			root.toggleDashboard();
		}
	}
}
