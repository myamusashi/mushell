pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Notifications

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	active: Notifs.notifications.popupNotifications.length > 0
	asynchronous: true
	sourceComponent: PanelWindow {
		id: root

		anchors {
			right: true
			top: true
		}

		WlrLayershell.namespace: "shell:notification"
		exclusiveZone: 0
		color: "transparent"

		implicitWidth: 400
		implicitHeight: Math.min(700, notifListView.contentHeight + 20)
		visible: {
			if (!Notifs.notifications.isDnDDisabled && Notifs.notifications.popupNotifications.length > 0)
				return true;
			else
				return false;
		}

		ListView {
			id: notifListView

			anchors.right: parent.right
			anchors.top: parent.top
			anchors.fill: parent
			anchors.margins: 10
			spacing: Appearance.spacing.normal
			clip: true
			model: ScriptModel {
				values: [...Notifs.notifications.popupNotifications.map(a => a)].reverse()
			}

			delegate: Rectangle {
				id: delegateNotif

				required property Notification modelData

				property bool hasImage: modelData.image.length > 0
				property bool hasAppIcon: modelData.appIcon.length > 0
				property bool isPaused: false

				width: notifListView.width
				height: contentLayout.implicitHeight + 16
				color: modelData.urgency === NotificationUrgency.Critical ? Appearance.colors.on_error : Appearance.colors.surface
				radius: 8
				border.color: modelData.urgency === NotificationUrgency.Critical ? Appearance.colors.error : Appearance.colors.outline
				border.width: modelData.urgency === NotificationUrgency.Critical ? 3 : 1

				RetainableLock {
					id: retainNotif

					object: delegateNotif.modelData
					locked: true
				}

				Timer {
					id: closePopups

					interval: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000
					running: true

					onTriggered: {
						if (!delegateNotif.isPaused)
							Notifs.notifications.removePopupNotification(delegateNotif.modelData);
					}
				}

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
				}

				RowLayout {
					id: contentLayout

					anchors.fill: parent
					anchors.margins: 8
					spacing: Appearance.spacing.large * 2

					Loader {
						id: image

						active: delegateNotif.hasImage
						asynchronous: true

						visible: delegateNotif.hasImage || delegateNotif.hasAppIcon

						sourceComponent: ClippingRectangle {
							radius: Appearance.rounding.full
							implicitWidth: 60
							implicitHeight: 60

							Image {
								anchors.fill: parent
								source: Qt.resolvedUrl(delegateNotif.modelData.image)
								fillMode: Image.PreserveAspectCrop
								cache: false
								asynchronous: true
							}
						}
					}

					// Thank you Caelestia
					Loader {
						id: appIcon

						active: delegateNotif.hasAppIcon || !delegateNotif.hasImage
						asynchronous: true

						Layout.alignment: delegateNotif.hasImage ? undefined : Qt.AlignVCenter | Qt.AlignHCenter

						sourceComponent: Rectangle {
							radius: Appearance.rounding.full
							color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Appearance.colors.error : delegateNotif.modelData.urgency === NotificationUrgency.Low ? Appearance.colors.surface_container_highest : Appearance.colors.secondary_container

							Loader {
								id: icon

								active: delegateNotif.hasAppIcon
								asynchronous: true

								anchors.centerIn: parent

								width: Math.round(50)
								height: Math.round(50)

								sourceComponent: IconImage {
									anchors.fill: parent
									source: Quickshell.iconPath(delegateNotif.modelData.appIcon)
								}
							}

							Loader {
								active: !delegateNotif.hasAppIcon
								asynchronous: true
								anchors.centerIn: parent
								anchors.horizontalCenterOffset: -Appearance.fonts.large * 0.02
								anchors.verticalCenterOffset: Appearance.fonts.large * 0.02

								sourceComponent: MatIcon {
									text: "release_alert"

									color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Appearance.colors.on_error : delegateNotif.modelData.urgency === NotificationUrgency.Low ? Appearance.colors.on_surface : Appearance.colors.on_secondary_container
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
							Layout.alignment: Qt.AlignTop

							StyledText {
								id: appName
								Layout.fillWidth: true
								text: delegateNotif.modelData.appName
								font.pixelSize: Appearance.fonts.small * 0.9
								color: Appearance.colors.on_background
								elide: Text.ElideRight
							}

							MatIcon {
								Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
								icon: "close"
								font.pixelSize: Appearance.fonts.normal * 1.7
								color: mIcon.containsMouse ? Appearance.colors.withAlpha(Appearance.colors.error, 0.4) : Appearance.colors.error

								MouseArea {
									id: mIcon
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
							color: Appearance.colors.on_background
							font.bold: true
							elide: Text.ElideRight
							wrapMode: Text.WordWrap
						}

						StyledText {
							id: body

							Layout.fillWidth: true
							text: delegateNotif.modelData.body || ""
							font.pixelSize: Appearance.fonts.small * 1.2
							color: Appearance.colors.on_background
							textFormat: Text.MarkdownText
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
											console.log("Action clicked:", actionButton.modelData.text);
											actionButton.modelData.invoke();
										}

										Rectangle {
											id: ripple
											anchors.centerIn: parent
											width: 0
											height: 0
											radius: width / 2
											color: Qt.rgba(Appearance.colors.primary.r, Appearance.colors.primary.g, Appearance.colors.primary.b, 0.3)
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
										color: actionMouse.containsMouse ? Appearance.colors.on_primary_container : Appearance.colors.on_surface
										elide: Text.ElideRight
									}

									Behavior on color {
										NumbAnim {}
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
