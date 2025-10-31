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

		margins {
			right: 5
			top: 5
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
				property bool isShowMoreBody: false
				property bool isPaused: false

				implicitWidth: notifListView.width
				implicitHeight: contentLayout.implicitHeight + 32
				boundsBehavior: Flickable.DragAndOvershootBounds
				flickableDirection: Flickable.HorizontalFlick

				RetainableLock {
					id: retainNotif

					object: delegateNotif.modelData
					locked: true
				}

				Behavior on width {
					NumbAnim {}
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

					color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.error_container : Colors.colors.surface_container_low

					radius: Appearance.rounding.large

					layer.enabled: true
					layer.effect: MultiEffect {
						shadowEnabled: true
						shadowColor: Colors.withAlpha(Colors.colors.shadow, 0.15)
						shadowBlur: 0.4
						shadowVerticalOffset: 2
						shadowHorizontalOffset: 0
					}

					border.color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.error : "transparent"
					border.width: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? 1 : 0

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
						anchors.margins: 16
						spacing: Appearance.spacing.larger

						Behavior on width {
							NumbAnim {}
						}

						Item {
							Layout.alignment: Qt.AlignTop
							Layout.topMargin: 4
							Layout.preferredWidth: 40
							Layout.preferredHeight: 40

							Loader {
								id: appIcon

								active: delegateNotif.hasAppIcon || !delegateNotif.hasImage

								anchors.centerIn: parent
								width: 40
								height: 40
								sourceComponent: StyledRect {
									width: 40
									height: 40
									radius: Appearance.rounding.full
									color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.error : delegateNotif.modelData.urgency === NotificationUrgency.Low ? Colors.colors.secondary_container : Colors.colors.primary_container

									Loader {
										id: icon

										active: delegateNotif.hasAppIcon

										anchors.centerIn: parent
										width: 24
										height: 24
										sourceComponent: IconImage {
											anchors.centerIn: parent
											source: Quickshell.iconPath(delegateNotif.modelData.appIcon)
										}
									}

									Loader {
										active: !delegateNotif.hasAppIcon

										anchors.centerIn: parent
										sourceComponent: MatIcon {
											text: "notifications_active"
											color: delegateNotif.modelData.urgency === NotificationUrgency.Critical ? Colors.colors.on_error : delegateNotif.modelData.urgency === NotificationUrgency.Low ? Colors.colors.on_secondary_container : Colors.colors.on_primary_container
											font.pointSize: Appearance.fonts.normal
										}
									}
								}
							}

							Loader {
								id: image

								active: delegateNotif.hasImage

								anchors.right: parent.right
								anchors.bottom: parent.bottom
								anchors.rightMargin: -4
								anchors.bottomMargin: -4
								width: 20
								height: 20
								z: 1
								sourceComponent: StyledRect {
									width: 20
									height: 20
									radius: 10
									color: Colors.colors.surface
									border.color: Colors.colors.outline_variant
									border.width: 1.5

									ClippingRectangle {
										anchors.centerIn: parent
										radius: 8
										width: 16
										height: 16

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
													width: 16
													height: 16
													radius: 8
												}
											}
										}
									}
								}
							}
						}

						ColumnLayout {
							Layout.fillWidth: true
							spacing: Appearance.spacing.small

							RowLayout {
								Layout.fillWidth: true
								spacing: Appearance.spacing.small

								Item {
									Layout.fillWidth: true
									RowLayout {
										y: -10
										Layout.alignment: Qt.AlignTop
										StyledText {
											id: appName

											Layout.fillWidth: true
											text: delegateNotif.modelData.appName
											font.pixelSize: Appearance.fonts.large
											font.weight: Font.Medium
											color: Colors.colors.on_surface_variant
											elide: Text.ElideRight
										}

										StyledText {
											id: dots

											text: "•"
											color: Colors.colors.on_surface_variant
											font.pixelSize: Appearance.fonts.large
										}

										StyledText {
											id: whenTime

											text: {
												const now = new Date();
												return TimeAgo.timeAgoWithIfElse(now);
											}
											color: Colors.colors.on_surface_variant
										}
									}
								}

								StyledRect {
									id: expandButton

									Layout.preferredWidth: 32
									Layout.preferredHeight: 32

									radius: Appearance.rounding.large
									color: expandButtonMouse.pressed ? Colors.colors.secondary_container : expandButtonMouse.containsMouse ? Colors.withAlpha(Colors.colors.on_surface, 0.08) : "transparent"

									Behavior on color {
										ColorAnimation {
											duration: 100
										}
									}

									MatIcon {
										id: expandIcon

										anchors.centerIn: parent
										icon: delegateNotif.isShowMoreBody ? "expand_less" : "expand_more"
										font.pixelSize: Appearance.fonts.large + 5
										color: Colors.colors.on_surface_variant

										RotationAnimator on rotation {
											id: rotateArrowIcon

											from: 0
											to: 180
											duration: Appearance.animations.durations.normal
											easing.type: Easing.BezierSpline
											easing.bezierCurve: Appearance.animations.curves.standard
											running: false
										}
									}

									MouseArea {
										id: expandButtonMouse

										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: {
											delegateNotif.isShowMoreBody = !delegateNotif.isShowMoreBody;
											rotateArrowIcon.running = !rotateArrowIcon.running;
										}
									}
								}
							}

							StyledText {
								id: summary

								Layout.fillWidth: true
								text: delegateNotif.modelData.summary
								font.pixelSize: Appearance.fonts.normal * 1.1
								font.weight: Font.DemiBold
								color: Colors.colors.on_surface
								elide: Text.ElideRight
								wrapMode: Text.Wrap
								maximumLineCount: 2
							}

							StyledText {
								id: body

								Layout.fillWidth: true
								text: delegateNotif.modelData.body || ""
								font.pixelSize: Appearance.fonts.small * 1.1
								lineHeight: 1.4
								color: Colors.colors.on_surface_variant
								Layout.preferredWidth: parent.width
								elide: Text.ElideRight
								textFormat: delegateNotif.isShowMoreBody ? Text.MarkdownText : Text.StyledText
								wrapMode: delegateNotif.isShowMoreBody ? Text.WrapAtWordBoundaryOrAnywhere : Text.Wrap
								maximumLineCount: delegateNotif.isShowMoreBody ? 0 : 1
								visible: text.length > 0
								clip: true

								transformOrigin: Item.Top

								opacity: delegateNotif.isShowMoreBody ? 1.0 : 0.92
								Behavior on opacity {
									NumbAnim {
										duration: Appearance.animations.durations.small
										easing.type: Easing.OutQuad
									}
								}
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
										Layout.preferredHeight: 40

										required property NotificationAction modelData

										color: actionMouse.pressed ? Colors.colors.secondary_container : actionMouse.containsMouse ? Colors.colors.secondary_container : Colors.colors.surface_container_high

										radius: Appearance.rounding.full

										Behavior on color {
											ColorAnimation {
												duration: Appearance.animations.durations.small
												easing.type: Easing.OutCubic
											}
										}

										StyledRect {
											anchors.fill: parent
											radius: parent.radius
											color: actionMouse.pressed ? Colors.withAlpha(Colors.colors.on_secondary_container, 0.12) : actionMouse.containsMouse ? Colors.withAlpha(Colors.colors.on_secondary_container, 0.08) : "transparent"

											Behavior on color {
												ColorAnimation {
													duration: 100
												}
											}
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
										}

										StyledText {
											anchors.centerIn: parent
											text: actionButton.modelData.text
											font.pixelSize: Appearance.fonts.small * 1.05
											font.weight: Font.Medium
											color: Colors.colors.on_secondary_container
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
