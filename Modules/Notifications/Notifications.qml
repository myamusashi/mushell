pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Notifications

import qs.Data
import qs.Helpers
import qs.Components

LazyLoader {
	active: Notifs.notifications.popupNotifications.length > 0

	component: PanelWindow {
		id: root

		anchors {
			top: true
			right: true
		}

		WlrLayershell.namespace: "shell:notification"
		exclusiveZone: 0
		color: "transparent"

		implicitWidth: 300 * 1.5
		implicitHeight: Math.min(600, notifListView.contentHeight + 20)

		visible: {
			if (!Notifs.notifications.disabledDnD && Notifs.notifications.popupNotifications.length > 0)
				return true;
			else
				return false;
		}

		ListView {
			id: notifListView

			anchors.right: parent.right
			anchors.top: parent.top
			anchors.fill: parent

			spacing: Appearance.spacing.normal
			clip: true
			model: ScriptModel {
				values: [...Notifs.notifications.popupNotifications.map(a => a)].reverse()
			}

			add: Transition {
				NumbAnim {
					properties: "opacity"
					from: 0
					to: 1
				}
			}

			remove: Transition {
				NumbAnim {
					properties: "opacity"
					to: 0
				}
			}

			displaced: Transition {
				NumbAnim {
					properties: "y"
				}
			}

			delegate: Flickable {
				id: delegateNotif

				required property Notification modelData

				property bool hasImage: modelData.image.length > 0
				property bool hasAppIcon: modelData.appIcon.length > 0
				property bool isPaused: false

				implicitWidth: notifListView.width
				implicitHeight: contentLayout.implicitHeight * 1.3
				boundsBehavior: Flickable.DragAndOvershootBounds
				flickableDirection: Flickable.HorizontalFlick

				RetainableLock {
					id: retainNotif

					object: delegateNotif.modelData
					locked: true
				}

				Behavior on x {
					NumbAnim {
						duration: Appearance.animations.durations.expressiveDefaultSpatial
						easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
					}
				}

				Behavior on y {
					NumbAnim {
						duration: Appearance.animations.durations.expressiveDefaultSpatial
						easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
					}
				}

				Behavior on opacity {
					NumbAnim {
						duration: Appearance.animations.durations.small
						easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
					}
				}

				Timer {
					id: closePopups

					interval: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000
					running: true

					onTriggered: {
						Notifs.notifications.removePopupNotification(delegateNotif.modelData);
					}
				}

				StyledRect {
					anchors.fill: parent

					color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.on_error : Colors.colors.surface

					radius: 8
					border.color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.error : Colors.colors.outline
					border.width: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? 3 : 1

					MouseArea {
						id: delegateMouseNotif

						anchors.fill: parent

						hoverEnabled: true

						onEntered: {
							delegateNotif.isPaused = true;
							closePopups.stop();
						}

						onExited: {
							delegateNotif.isPaused = false;
							closePopups.start();
						}

						drag {
							axis: Drag.XAxis
							target: delegateNotif

							onActiveChanged: {
								if (delegateMouseNotif.drag.active)
									return;

								if (Math.abs(delegateNotif.x) > (delegateNotif.width * 0.45)) {
									Notifs.notifications.removePopupNotification(delegateNotif.modelData);
									Notifs.notifications.removeListNotification(delegateNotif.modelData);
								} else
									delegateNotif.x = 0;
							}
						}
					}

					RowLayout {
						id: contentLayout

						anchors.fill: parent

						anchors.margins: 10
						spacing: Appearance.spacing.large * 1.5

						Item {
							Layout.alignment: Qt.AlignCenter
							Layout.preferredWidth: 65
							Layout.preferredHeight: 65

							Loader {
								id: appIcon

								active: delegateNotif.hasAppIcon || !delegateNotif.hasImage

								anchors.centerIn: parent
								width: 65
								height: 65
								sourceComponent: StyledRect {
									width: 65
									height: 65
									radius: Appearance.rounding.full
									color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.error : delegateNotif.modelData.urgency === NotificationUrgency.Low ? Colors.colors.surface_container_highest : Colors.colors.secondary_container

									Loader {
										id: icon

										active: delegateNotif.hasAppIcon

										anchors.centerIn: parent
										width: 65
										height: 65
										sourceComponent: IconImage {
											anchors.centerIn: parent
											source: Quickshell.iconPath(delegateNotif.modelData.appIcon)
										}
									}

									Loader {
										active: !delegateNotif.hasAppIcon

										anchors.centerIn: parent
										anchors.horizontalCenterOffset: -Appearance.fonts.large * 0.02
										anchors.verticalCenterOffset: Appearance.fonts.large * 0.02
										sourceComponent: MatIcon {
											text: "release_alert"
											color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.on_error : delegateNotif.modelData.urgency === NotificationUrgency.Low ? Colors.colors.on_surface : Colors.colors.on_secondary_container
											font.pointSize: Appearance.fonts.large
										}
									}
								}
							}

							Loader {
								id: image

								active: delegateNotif.hasImage

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

											source: Qt.resolvedUrl(delegateNotif.modelData.image)
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
							spacing: 4

							RowLayout {
								Layout.fillWidth: true
								Layout.alignment: Qt.AlignTop

								StyledText {
									id: appName

									Layout.fillWidth: true
									text: delegateNotif.modelData.appName
									font.pixelSize: Appearance.fonts.small * 0.9
									color: Colors.colors.on_background
									elide: Text.ElideRight
								}

								MatIcon {
									Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
									icon: "close"
									font.pixelSize: Appearance.fonts.normal * 1.7
									color: mArea.containsMouse ? Colors.withAlpha(Colors.colors.error, 0.4) : Colors.colors.error

									MouseArea {
										id: mArea

										anchors.fill: parent

										hoverEnabled: true

										onClicked: mevent => {
											if (mevent.button === Qt.LeftButton) {
												Notifs.notifications.removePopupNotification(delegateNotif.modelData);
												Notifs.notifications.removeListNotification(delegateNotif.modelData);
											}
										}
									}
								}
							}

							StyledText {
								id: summary

								Layout.fillWidth: true
								text: delegateNotif.modelData.summary
								font.pixelSize: Appearance.fonts.normal
								color: Colors.colors.on_background
								font.bold: true

								elide: Text.ElideRight
								wrapMode: Text.WordWrap
							}

							StyledText {
								id: body

								Layout.fillWidth: true
								text: delegateNotif.modelData.body || ""
								font.pixelSize: Appearance.fonts.small * 1.2
								color: Colors.colors.on_background
								textFormat: Text.MarkdownText
								maximumLineCount: 4
								Layout.preferredWidth: parent.width
								wrapMode: Text.WrapAtWordBoundaryOrAnywhere
								visible: text.length > 0
							}

							RowLayout {
								Layout.fillWidth: true
								Layout.topMargin: 8
								spacing: 8
								visible: delegateNotif.modelData?.actions && delegateNotif.modelData.actions.length > 0

								Repeater {
									model: delegateNotif.modelData?.actions

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
												Notifs.notifications.removePopupNotification(delegateNotif.modelData);
												Notifs.notifications.removeListNotification(delegateNotif.modelData);
											}

											StyledRect {
												id: ripple

												anchors.centerIn: parent
												width: 0
												height: 0
												radius: width / 2
												color: Colors.withAlpha(Colors.colors.primary, 03)
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
