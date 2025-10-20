pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	active: true

	anchors.fill: parent

	sourceComponent: StyledRect {
		id: root

		Layout.fillWidth: true
		Layout.fillHeight: true
		color: Colors.colors.background
		radius: Appearance.rounding.normal
		border.color: Colors.colors.outline
		border.width: 2

		ScrollView {
			anchors.fill: parent

			anchors.margins: 16
			clip: true

			Behavior on y {
				NumbAnim {}
			}

			// Lmao just copy the code from Notifications.qml
			ListView {
				id: listViewNotifs

				model: ScriptModel {
					values: [...Notifs.notifications.listNotifications.map(a => a)].reverse()
				}

				delegate: Flickable {
					id: flickDelegate

					width: parent.width
					height: Math.max(150, contentLayout.implicitHeight + 20)

					contentWidth: width

					contentHeight: height
					boundsBehavior: Flickable.DragAndOvershootBounds
					flickableDirection: Flickable.HorizontalFlick

					required property Notification modelData

					property bool hasImage: modelData.image.length > 0
					property bool hasAppIcon: modelData.appIcon.length > 0

					Behavior on x {
						NumbAnim {}
					}

					RetainableLock {
						object: flickDelegate.modelData
						locked: true
					}

					StyledRect {
						id: rectNotification

						width: listViewNotifs.width
						height: Math.max(120, contentLayout.implicitHeight + 10)
						color: Colors.withAlpha(Colors.colors.on_background, 0.07)
						radius: Appearance.rounding.normal

						MouseArea {
							id: delegateMouseNotif

							anchors.fill: parent

							hoverEnabled: true

							drag {
								axis: Drag.XAxis
								target: flickDelegate

								onActiveChanged: {
									if (delegateMouseNotif.drag.active)
										return;

									if (Math.abs(flickDelegate.x) > (flickDelegate.width * 0.45)) {
										Notifs.notifications.removePopupNotification(flickDelegate.modelData);
										Notifs.notifications.removeListNotification(flickDelegate.modelData);
									} else
										flickDelegate.x = 0;
								}
							}
						}

						RowLayout {
							id: contentLayout

							anchors.fill: parent

							anchors.topMargin: 10
							anchors.leftMargin: 35
							Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
							spacing: 8

							Item {
								Layout.alignment: Qt.AlignCenter
								Layout.rightMargin: 40
								Layout.preferredWidth: 65
								Layout.preferredHeight: 65

								Loader {
									id: appIcon

									active: flickDelegate.hasAppIcon || !flickDelegate.hasImage
									asynchronous: true

									anchors.centerIn: parent
									width: 65
									height: 65
									sourceComponent: StyledRect {
										width: 65
										height: 65
										radius: Appearance.rounding.full
										color: flickDelegate.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.error : flickDelegate.modelData.urgency === NotificationUrgency.Low ? Colors.colors.surface_container_highest : Colors.colors.secondary_container

										Loader {
											id: icon

											active: flickDelegate.hasAppIcon
											asynchronous: true

											anchors.centerIn: parent
											width: 65
											height: 65
											sourceComponent: IconImage {
												anchors.centerIn: parent
												source: Quickshell.iconPath(flickDelegate.modelData.appIcon)
											}
										}

										Loader {
											active: !flickDelegate.hasAppIcon
											asynchronous: true

											anchors.centerIn: parent
											anchors.horizontalCenterOffset: -Appearance.fonts.large * 0.02
											anchors.verticalCenterOffset: Appearance.fonts.large * 0.02
											sourceComponent: MatIcon {
												text: "release_alert"
												color: flickDelegate.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.on_error : flickDelegate.modelData.urgency === NotificationUrgency.Low ? Colors.colors.on_surface : Colors.colors.on_secondary_container
												font.pointSize: Appearance.fonts.large
											}
										}
									}
								}

								Loader {
									id: image

									active: flickDelegate.hasImage
									asynchronous: true

									anchors.right: parent.right
									anchors.bottom: parent.bottom
									anchors.rightMargin: -5
									anchors.bottomMargin: -5
									width: 28
									height: 28
									z: 1
									sourceComponent: StyledRect {
										width: 28
										height: 28
										radius: width / 2
										color: "white"
										border.color: Colors.colors.surface
										border.width: 2

										ClippingRectangle {
											anchors.centerIn: parent
											radius: width / 2
											width: 24
											height: 24

											Image {
												anchors.fill: parent

												source: Qt.resolvedUrl(flickDelegate.modelData.image)
												fillMode: Image.PreserveAspectCrop
												cache: false
												asynchronous: true

												layer.enabled: true
												layer.effect: MultiEffect {
													maskEnabled: true

													maskSource: StyledRect {
														width: 24
														height: 24
														radius: width / 2
													}
												}
											}
										}
									}
								}
							}

							ColumnLayout {
								Layout.fillWidth: true
								Layout.alignment: Qt.AlignTop
								spacing: 4

								RowLayout {
									Layout.fillWidth: true
									Layout.fillHeight: true
									Layout.rightMargin: 5

									StyledText {
										id: appName

										Layout.fillWidth: true
										text: flickDelegate.modelData.appName
										font.pixelSize: Appearance.fonts.small * 0.9
										color: Colors.colors.on_background
										elide: Text.ElideRight
									}

									MatIcon {
										icon: "close"
										font.pixelSize: Appearance.fonts.large * 1.8
										color: mIcon.containsMouse ? Colors.withAlpha(Colors.colors.error, 0.4) : Colors.colors.error

										MouseArea {
											id: mIcon

											anchors.fill: parent

											hoverEnabled: true

											onClicked: mevent => {
												if (mevent.button === Qt.LeftButton) {
													Notifs.notifications.removeListNotification(flickDelegate.modelData);
												}
											}
										}
									}
								}

								StyledText {
									id: summary

									Layout.fillWidth: true
									text: flickDelegate.modelData.summary
									font.pixelSize: Appearance.fonts.normal
									color: Colors.colors.on_background
									font.bold: true

									elide: Text.ElideRight
									wrapMode: Text.WordWrap
								}

								StyledText {
									id: body

									Layout.fillWidth: true
									text: flickDelegate.modelData.body || ""
									font.pixelSize: Appearance.fonts.small * 1.2
									color: Colors.colors.on_background
									textFormat: Text.MarkdownText
									Layout.preferredWidth: parent.width
									wrapMode: Text.WrapAtWordBoundaryOrAnywhere
									visible: text.length > 0
								}

								RowLayout {
									Layout.topMargin: 8
									Layout.rightMargin: 8
									Layout.bottomMargin: 15
									spacing: 8
									visible: flickDelegate.modelData?.actions && flickDelegate.modelData.actions.length > 0

									Repeater {
										model: flickDelegate.modelData?.actions

										delegate: StyledRect {
											id: actionButton

											Layout.fillWidth: true
											Layout.preferredHeight: 36

											required property NotificationAction modelData

											color: actionMouse.pressed ? Colors.colors.primary_container : actionMouse.containsMouse ? Colors.colors.surface_container_highest : Colors.colors.surface_container_high

											border.color: actionMouse.containsMouse ? Colors.colors.primary : Colors.colors.outline
											border.width: actionMouse.containsMouse ? 2 : 1
											radius: 6

											StyledRect {
												anchors.fill: parent

												anchors.topMargin: 1
												color: "transparent"
												border.color: Colors.withAlpha(Colors.colors.background, 0.01)
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
													Notifs.notifications.removePopupNotification(flickDelegate.modelData);
													Notifs.notifications.removeListNotification(flickDelegate.modelData);
													flickDelegate.modelData.dismiss();
												}

												StyledRect {
													id: ripple

													anchors.centerIn: parent

													width: 0
													height: 0
													radius: width / 2
													color: Colors.withAlpha(Colors.colors.primary, 0.3)
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

											StyledText {
												id: actionText

												anchors.centerIn: parent
												text: actionButton.modelData.text
												font.pixelSize: Appearance.fonts.small * 1.1
												font.weight: actionMouse.containsMouse ? Font.Medium : Font.Normal
												color: actionMouse.containsMouse ? Colors.colors.on_primary_container : Colors.colors.on_surface
												elide: Text.ElideRight
											}

											Behavior on color {
												ColAnim {}
											}
											Behavior on border.color {
												ColAnim {}
											}
											Behavior on border.width {
												NumbAnim {}
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
