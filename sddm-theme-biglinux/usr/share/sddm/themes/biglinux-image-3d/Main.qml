/*
 *   Copyright 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import Qt5Compat.GraphicalEffects 1.0
import org.kde.plasma.plasma5support 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.15 as Kirigami
import org.kde.breeze.components
import "components"

Item {
    id: root

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    width: Screen.width
    height: Screen.height

    property string notificationMessage

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    PlasmaCore.DataSource {
        id: keystateSource
        engine: "keystate"
        connectedSources: "Caps Lock"
    }

    Image {
        id: wallpaper
        height: parent.height
        width: parent.width
        source: if (config.type == "color") {
                    config.default_background;
                } else {
                    config.background;
                }
        asynchronous: true
        cache: true
        clip: true
        visible: true
    }

    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent

        property bool uiVisible: true
        property bool blockUI: mainStack.depth > 1 || userListComponent.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive || config.type != "image"

        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }

        Keys.onPressed: {
            uiVisible = true;
            event.accepted = false;
        }

        //takes one full minute for the ui to disappear
        Timer {
            id: fadeoutTimer
            running: true
            interval: 60000
            onTriggered: {
                if (!loginScreenRoot.blockUI) {
                    loginScreenRoot.uiVisible = false;
                }
            }
        }

        Rectangle {
            id: formBg
            width: mainStack.width
            height: mainStack.height
            x: root.width / 2 - width / 2
            y: root.height / 2 - height / 2
            radius: 16
            color: "#1e1e1e"
            opacity: 0.6
            z: -1
            visible: true

            transform: [
                Rotation {
                    id: rotationX
                    axis.x: 1
                    axis.y: 0
                    origin.x: formBg.width / 2
                    origin.y: formBg.height / 2
                    angle: 0
                },
                Rotation {
                    id: rotationY
                    axis.x: 0
                    axis.y: 1
                    origin.x: formBg.width / 2
                    origin.y: formBg.height / 2
                    angle: 0
                }
            ]
        }

        StackView {
            id: mainStack
            anchors.centerIn: parent
            height: root.height / 1.3
            width: parent.width / 2

            focus: true // StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

                MouseArea {
            id: mouseArea
                anchors.fill: parent
                anchors.margins: -root.width
            hoverEnabled: true
            onPositionChanged: {
                var centerX = width / 2;
                var centerY = height / 2;
                var offsetX = (mouse.x - centerX) / centerX;
                var offsetY = (mouse.y - centerY) / centerY;
                rotationX.angle = -offsetY * 10;
                rotationY.angle = offsetX * 10;
                rotationXStack.angle = -offsetY * 10;
                rotationYStack.angle = offsetX * 10;
            }
        }

            transform: [
                Rotation {
                    id: rotationXStack
                    axis.x: 1
                    axis.y: 0
                    origin.x: mainStack.width / 2
                    origin.y: mainStack.height / 2
                    angle: 0
                },
                Rotation {
                    id: rotationYStack
                    axis.x: 0
                    axis.y: 1
                    origin.x: mainStack.width / 2
                    origin.y: mainStack.height / 2
                    angle: 0
                }
            ]

            initialItem: Login {
                id: userListComponent
                userListModel: userModel
                loginScreenUiVisible: loginScreenRoot.uiVisible
                userListCurrentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                lastUserName: userModel.lastUser

                showUserList: {
                    if (!userListModel.hasOwnProperty("count")
                        || !userListModel.hasOwnProperty("disableAvatarsThreshold"))
                        return (userList.y + mainStack.y) > 0

                    if (userListModel.count == 0) return false

                    return userListModel.count <= userListModel.disableAvatarsThreshold && (userList.y + mainStack.y) > 0
                }

                notificationMessage: {
                    var text = ""
                    if (keystateSource.data["Caps Lock"]["Locked"]) {
                        text += i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Caps Lock is on")
                        if (root.notificationMessage) {
                            text += " • "
                        }
                    }
                    text += root.notificationMessage
                    return text
                }

                RowLayout {
                    id: footer
                    width: parent.width
                    height: implicitHeight
                    anchors {
                        top: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }

                    Behavior on opacity {
                        OpacityAnimator {
                            duration: units.longDuration
                        }
                    }

                    SessionButton {
                        id: sessionButton
                        Rectangle {
                            anchors.fill: parent
                            color: "#ffffff"
                            opacity: 0.1
                            radius: 20
                            anchors.leftMargin: -15
                            anchors.rightMargin: -15
                        }
                        opacity: 0.5
                    }
                }

                actionItems: [
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/suspend.svg")
                        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Suspend to RAM", "Sleep")
                        onClicked: sddm.suspend()
                        enabled: sddm.canSuspend
                        visible: !inputPanel.keyboardActive
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/restart.svg")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Restart")
                        onClicked: sddm.reboot()
                        enabled: sddm.canReboot
                        visible: !inputPanel.keyboardActive
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/shutdown.svg")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Shut Down")
                        onClicked: sddm.powerOff()
                        enabled: sddm.canPowerOff
                        visible: !inputPanel.keyboardActive
                    }
                ]

                onLoginRequest: {
                    root.notificationMessage = ""
                    sddm.login(username, password, sessionButton.currentIndex)
                }

                Behavior on opacity {
                    OpacityAnimator {
                        duration: units.longDuration
                    }
                }
            }

PlasmaComponents.ToolButton {
    id: virtualKeyboardButton
    // Não define o texto diretamente aqui para evitar duplicação
    font.pointSize: config.fontSize
    opacity: 0.6
    width: virtualKeyboardButtonLabel.width + 50
    height: 30
    
    icon.name: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                onClicked: {
                    // Otherwise the password field loses focus and virtual keyboard
                    // keystrokes get eaten
                    userListComponent.mainPasswordBox.forceActiveFocus();
                    inputPanel.showHide()
                }
    visible: inputPanel.status == Loader.Ready
    anchors.left: mainStack.left
    anchors.top: mainStack.top
    anchors.topMargin: 10
    anchors.leftMargin: 20

    contentItem: Row {
        spacing: 5
        id: iconVirtualKeyboard
        anchors.centerIn: parent
        z: -2
        Kirigami.Icon {
            source: virtualKeyboardButton.icon.name
            width: 24
            height: 24
        }

        Text {
            id: virtualKeyboardButtonLabel
            text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to show/hide virtual keyboard", "Virtual Keyboard")
            color: "transparent" // Inicialmente transparente
            font.pointSize: config.fontSize
            anchors.right: iconVirtualKeyboard.right
            anchors.rightMargin: 10
        }

        MouseArea {
            id: hoverAreaKeyboard
            anchors.fill: parent
            hoverEnabled: true

            onEntered: virtualKeyboardButtonLabel.color = "white"  // Cor visível
            onExited: virtualKeyboardButtonLabel.color = "transparent" // Cor transparente
        }
    }
}

KeyboardButton { }
            Battery {
                anchors.right: mainStack.right
                anchors.top: mainStack.top
                anchors.topMargin: 10
                anchors.rightMargin: 25
            }

            Clock {
                id: clock
                visible: true
                anchors.horizontalCenter: mainStack.horizontalCenter
                anchors.top: mainStack.top
                anchors.topMargin: 20
                opacity: 0.8
            }
        }

        VirtualKeyboardLoader {
            id: inputPanel
            z: 1
            screenRoot: root
            mainStack: mainStack
            mainBlock: userListComponent
            passwordField: userListComponent.mainPasswordBox
        }


        ShaderEffectSource {
            id: blurSource
            sourceItem: wallpaper
            anchors.fill: formBg
            sourceRect: Qt.rect(formBg.x, formBg.y, formBg.width, formBg.height)
            visible: false
        }

        MultiEffect {
            source: blurSource
            anchors.fill: formBg

            autoPaddingEnabled: true
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            z: -2
        }
    }

Connections {
    target: sddm
    function onLoginFailed() {
        notificationMessage = i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Login Failed");
    }
}


    onNotificationMessageChanged: {
        if (notificationMessage) {
            notificationResetTimer.start();
        }
    }

    Timer {
        id: notificationResetTimer
        interval: 3000
        onTriggered: notificationMessage = ""
    }
}
