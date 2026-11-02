pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "Singletons"

/**
 * The passphrase card. gpg-agent, sudo -A and ssh all end up here: the shim
 * sends one request (kind, title, description, prompt, error) over the shell's
 * socket and this card answers with the typed secret or a dismissal.
 *
 * The field borrows the lock's capsule: one ember bead per typed character
 * instead of bullets, a cream wick tip on the freshest bead, and the eye
 * swaps beads for the plain string. `kind` picks the shape:
 *
 *   pin      masked field, Enter submits, Escape cancels
 *   confirm  a question with yes/no buttons
 *   message  a notice with one button
 */
FocusScope {
    id: card

    property real s: 1
    property var request: null

    signal accepted(string text)
    signal dismissed()

    readonly property bool shown: request !== null
    readonly property string kind: request && request.kind ? String(request.kind) : "pin"
    readonly property bool secret: kind === "pin"
    readonly property string title: text(request, "title", "PASSPHRASE")
    readonly property string desc: text(request, "desc", "")
    readonly property string prompt: text(request, "prompt", "")
    readonly property string error: text(request, "error", "")
    readonly property string okLabel: text(request, "ok", secret ? "Unlock" : "Confirm")
    readonly property string cancelLabel: text(request, "cancel", "Cancel")
    readonly property string source: text(request, "source", "gpg")
    readonly property string kicker: {
        if (kind !== "pin")
            return "REQUEST";
        if (source === "sudo")
            return "SUPERUSER";
        if (source === "ssh")
            return "SSH KEY";
        if (source === "askpass")
            return "PASSWORD";
        return "GPG KEY";
    }
    readonly property string glyph: kind === "confirm" ? "請" : kind === "message" ? "報" : "鍵"

    property bool reveal: false

    function text(req, key, fallback) {
        if (req && req[key] !== undefined && String(req[key]).length > 0)
            return String(req[key]);
        return fallback;
    }

    focus: shown
    enabled: shown

    onRequestChanged: {
        reveal = false;
        input.text = "";
        if (shown)
            Qt.callLater(card.takeFocus);
    }

    function takeFocus() {
        if (card.secret && input.visible)
            input.forceActiveFocus();
        else
            card.forceActiveFocus();
    }

    Keys.onEscapePressed: card.dismissed()

    Keys.onReturnPressed: {
        if (!card.secret)
            card.accepted("");
    }

    /** Dim the desktop so the card has the screen to itself. */
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: card.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 110 }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    Rectangle {
        id: frame
        anchors.centerIn: parent
        width: 440 * card.s
        height: layout.implicitHeight + 64 * card.s
        radius: 18 * card.s
        color: Theme.cardBot
        border.width: 1
        border.color: Theme.border
        opacity: card.shown ? 1 : 0
        scale: card.shown ? 1 : 0.97
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 12 * card.s
            shadowHorizontalOffset: 0
        }
        Behavior on opacity {
            NumberAnimation { duration: 130 }
        }
        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.cardTop }
                GradientStop { position: 1; color: Theme.cardBot }
            }
        }

        Column {
            id: layout
            x: 28 * card.s
            y: 32 * card.s
            width: parent.width - 56 * card.s
            spacing: 14 * card.s

            Row {
                width: parent.width
                spacing: 14 * card.s

                Item {
                    width: 46 * card.s
                    height: 46 * card.s
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.alpha(Theme.verm, 0.16)
                        border.width: 1
                        border.color: Qt.alpha(Theme.vermLit, 0.45)
                    }
                    Text {
                        anchors.centerIn: parent
                        text: card.glyph
                        color: Theme.vermLit
                        font.family: Theme.fontJp
                        font.pixelSize: 21 * card.s
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3 * card.s

                    Text {
                        text: card.kicker
                        color: Theme.dim
                        font.family: Theme.font
                        font.weight: 600
                        font.pixelSize: 9 * card.s
                        font.letterSpacing: 3 * card.s
                    }
                    Text {
                        text: card.title
                        color: Theme.bright
                        font.family: Theme.font
                        font.weight: 600
                        font.pixelSize: 15 * card.s
                        font.letterSpacing: 2 * card.s
                        font.capitalization: Font.AllUppercase
                        elide: Text.ElideRight
                        width: layout.width - 46 * card.s - 14 * card.s
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.hair
            }

            Text {
                width: parent.width
                visible: card.desc.length > 0
                text: card.desc
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 12.5 * card.s
                lineHeight: 1.35
                wrapMode: Text.Wrap
            }

            Text {
                width: parent.width
                visible: card.error.length > 0
                text: card.error
                color: Theme.error
                font.family: Theme.font
                font.weight: 500
                font.pixelSize: 12 * card.s
                wrapMode: Text.Wrap
            }

            Text {
                visible: card.secret && card.prompt.length > 0
                text: card.prompt.replace(/:$/, "")
                color: Theme.dim
                font.family: Theme.font
                font.weight: 600
                font.pixelSize: 9.5 * card.s
                font.letterSpacing: 2.4 * card.s
                font.capitalization: Font.AllUppercase
            }

            /** The lock's capsule, shrunk to the card. */
            Rectangle {
                id: capsule
                width: parent.width
                height: 48 * card.s
                radius: height / 2
                color: Theme.fieldBg
                border.width: 1
                border.color: input.activeFocus ? Qt.alpha(Theme.vermLit, 0.75) : Theme.fieldBorder
                visible: card.secret

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 22 * card.s
                    anchors.rightMargin: 48 * card.s
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Normal
                    color: card.reveal ? Theme.bright : "transparent"
                    selectionColor: Theme.vermDeep
                    selectedTextColor: Theme.bright
                    font.family: Theme.font
                    font.pixelSize: 15 * card.s
                    font.letterSpacing: 1.6 * card.s
                    clip: true
                    focus: card.shown && card.secret
                    enabled: card.shown

                    onTextChanged: {
                        while (beadModel.count < text.length)
                            beadModel.append({});
                        while (beadModel.count > text.length)
                            beadModel.remove(beadModel.count - 1);
                    }

                    onAccepted: {
                        if (text.length > 0)
                            card.accepted(text);
                    }

                    cursorDelegate: Rectangle {
                        visible: card.reveal && input.text.length > 0
                        width: 2 * card.s
                        height: input.cursorRectangle.height
                        color: Theme.verm
                        SequentialAnimation on opacity {
                            running: input.activeFocus
                            loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 0 }
                            PauseAnimation { duration: 550 }
                            NumberAnimation { to: 1; duration: 0 }
                            PauseAnimation { duration: 550 }
                        }
                    }
                }

                ListModel { id: beadModel }

                /**
                 * The beads scroll instead of spilling past the capsule: the
                 * freshest stays at the right edge and older ones drop off the
                 * left, like the text they stand for.
                 */
                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 22 * card.s
                    anchors.rightMargin: 48 * card.s
                    clip: true

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9 * card.s
                        visible: !card.reveal && input.text.length > 0

                        Repeater {
                            model: beadModel
                            delegate: Rectangle {
                                id: bead
                                required property int index
                                width: 7 * card.s
                                height: width
                                radius: width / 2
                                color: bead.index === input.text.length - 1 ? Theme.cream : Theme.verm
                                scale: 0
                                Component.onCompleted: pop.start()
                                NumberAnimation { id: pop; target: bead; property: "scale"; to: 1; duration: 170; easing.type: Easing.OutBack }
                                SequentialAnimation on opacity {
                                    running: bead.index === input.text.length - 1
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.35; duration: 480 }
                                    NumberAnimation { to: 1; duration: 480 }
                                }
                            }
                        }
                    }
                }

                Eye {
                    id: eye
                    anchors.right: parent.right
                    anchors.rightMargin: 16 * card.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20 * card.s
                    height: 20 * card.s
                    name: card.reveal ? "eye-off" : "eye"
                    color: eyeArea.containsMouse ? Theme.cream : Theme.dim
                    stroke: 1.8

                    MouseArea {
                        id: eyeArea
                        anchors.fill: parent
                        anchors.margins: -6 * card.s
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.reveal = !card.reveal
                    }
                }
            }

            /** confirm/message: the same capsule shape, split into buttons. */
            Row {
                width: parent.width
                spacing: 10 * card.s
                visible: !card.secret

                Rectangle {
                    width: card.kind === "message" ? parent.width : (parent.width - 10 * card.s) / 2
                    height: 44 * card.s
                    radius: height / 2
                    color: yesArea.containsMouse ? Theme.vermLit : Theme.verm
                    border.width: 1
                    border.color: Theme.vermDeep

                    Text {
                        anchors.centerIn: parent
                        text: card.okLabel
                        color: Theme.bright
                        font.family: Theme.font
                        font.weight: 600
                        font.pixelSize: 12 * card.s
                        font.letterSpacing: 1.4 * card.s
                        font.capitalization: Font.AllUppercase
                    }
                    MouseArea {
                        id: yesArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.accepted("")
                    }
                }

                Rectangle {
                    visible: card.kind !== "message"
                    width: (parent.width - 10 * card.s) / 2
                    height: 44 * card.s
                    radius: height / 2
                    color: noArea.containsMouse ? Theme.fieldBg : "transparent"
                    border.width: 1
                    border.color: Theme.fieldBorder

                    Text {
                        anchors.centerIn: parent
                        text: card.cancelLabel
                        color: Theme.subtle
                        font.family: Theme.font
                        font.weight: 500
                        font.pixelSize: 12 * card.s
                        font.letterSpacing: 1.4 * card.s
                        font.capitalization: Font.AllUppercase
                    }
                    MouseArea {
                        id: noArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.dismissed()
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignRight
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9.5 * card.s
                font.letterSpacing: 1.4 * card.s
                text: card.secret ? "ENTER TO CONFIRM  ·  ESC TO CANCEL" : "ESC TO CANCEL"
            }
        }
    }
}
