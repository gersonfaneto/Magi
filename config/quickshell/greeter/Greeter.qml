pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import "Singletons"

/**
 * The login card: user name, password, clock and the greetd handshake. Kept
 * separate from the surface so the shell file only owns outputs and backdrop.
 *
 * Auth flow (see Quickshell.Services.Greetd):
 *   Inactive --createSession--> Authenticating --authMessage(secret)--> respond
 *   --success--> ReadyToLaunch --launch--> Quickshell exits, greetd starts the
 *   session. A failure drops back to Inactive and keeps the card up.
 */
Item {
    id: root

    readonly property string userName: Quickshell.env("GREETER_USER") || "gerson"
    readonly property var sessionCmd: {
        var fallback = ["uwsm", "start", "-e", "-D", "Hyprland", "hyprland.desktop"];
        try {
            var raw = Quickshell.env("GREETER_SESSION") || "";
            if (raw.length === 0)
                return fallback;
            var parsed = JSON.parse(raw);
            return (Array.isArray(parsed) && parsed.length > 0) ? parsed : fallback;
        } catch (e) {
            return fallback;
        }
    }
    readonly property var sessionEnv: [
        "XDG_SESSION_TYPE=wayland",
        "XDG_CURRENT_DESKTOP=Hyprland",
        "XDG_SESSION_DESKTOP=hyprland-uwsm",
        "PATH=/run/current-system/sw/bin:/run/wrappers/bin"
    ]

    property string errorText: ""
    property bool expecting: false
    property bool busy: false
    property bool launching: false
    property date now: new Date()

    /** greetd is waiting on the reader, not on a password. */
    readonly property bool scanning: Greetd.available
        && Greetd.state === GreetdState.Authenticating
        && !root.expecting
        && !root.busy

    /**
     * Start greetd's PAM transaction before anyone types. greetd's stack puts
     * pam_fprintd before the password prompt (see
     * modules/profiles/hardware/fingerprint.nix), so this is what gives the
     * greeter a fingerprint window. The repeating timer also restarts the
     * transaction after a failed attempt.
     */
    function startAuth(): void {
        if (root.launching || !Greetd.available || Greetd.state !== GreetdState.Inactive || root.busy)
            return;
        root.errorText = "";
        Greetd.createSession(root.userName);
    }

    /**
     * Tap-to-scan. If a password prompt is already open, drop that transaction
     * and let greetd start a fresh one so the reader gets another window.
     */
    function fingerprint(): void {
        if (root.launching || !Greetd.available)
            return;
        root.errorText = "";
        root.expecting = false;
        pw.text = "";
        if (Greetd.state === GreetdState.Authenticating) {
            root.busy = true;
            Greetd.cancelSession();
            refinger.restart();
            return;
        }
        root.busy = false;
        root.startAuth();
    }

    Timer {
        id: refinger
        interval: 150
        onTriggered: {
            root.busy = false;
            root.startAuth();
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.startAuth()
    }

    function submit(): void {
        root.errorText = "";
        if (root.expecting) {
            var value = pw.text;
            pw.text = "";
            root.expecting = false;
            root.busy = true;
            Greetd.respond(value);
            return;
        }
        if (Greetd.state === GreetdState.Inactive) {
            if (pw.text.length === 0)
                return;
            root.busy = true;
            Greetd.createSession(root.userName);
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (error && message.length > 0)
                root.errorText = message;
            if (!responseRequired)
                return;
            root.expecting = true;
            if (pw.text.length > 0) {
                var value = pw.text;
                pw.text = "";
                root.expecting = false;
                root.busy = true;
                Greetd.respond(value);
            } else {
                pw.forceActiveFocus();
            }
        }

        function onAuthFailure(message) {
            root.busy = false;
            root.expecting = false;
            pw.text = "";
            root.errorText = message.length > 0 ? message : "Authentication failed";
        }

        function onError(message) {
            root.busy = false;
            root.expecting = false;
            root.errorText = message.length > 0 ? message : "Greetd error";
        }

        function onReadyToLaunch() {
            root.launching = true;
            Greetd.launch(root.sessionCmd, root.sessionEnv, true);
        }

        function onStateChanged() {
            if (Greetd.state === GreetdState.Inactive && root.expecting === false)
                root.busy = false;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.86, 340)
        spacing: 14

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 54
            height: 54
            radius: 27
            color: Theme.fieldBg
            border.width: 1
            border.color: Theme.fieldBorder

            GlyphIcon {
                anchors.centerIn: parent
                width: 24
                height: 24
                name: "lock"
                color: Theme.cream
            }
        }

        Item { width: 1; height: 4 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: Theme.bright
            font.family: Theme.font
            font.pixelSize: 58
            font.weight: Font.Light
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.now, "dddd, MMMM d")
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 15
        }

        Item { width: 1; height: 10 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.userName
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 17
            font.weight: Font.Medium
        }

        Rectangle {
            width: parent.width
            height: 46
            radius: 23
            color: Theme.fieldBg
            border.width: 1
            border.color: root.errorText.length > 0 ? Theme.error : Theme.fieldBorder

            TextInput {
                id: pw
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 46
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "\u25cf"
                color: Theme.bright
                selectionColor: Theme.verm
                selectedTextColor: Theme.bright
                font.family: Theme.font
                font.pixelSize: 16
                enabled: Greetd.available && !root.busy
                onAccepted: root.submit()
                Component.onCompleted: forceActiveFocus()

                Text {
                    anchors.centerIn: parent
                    visible: pw.text.length === 0
                    text: root.busy ? "Checking..." : "Password"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 15
                }
            }

            /** Tap to drop a stale password prompt and give the reader a fresh window. */
            GlyphIcon {
                id: fingerIcon
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                name: "fingerprint"
                stroke: 1.8
                color: root.errorText.length > 0
                    ? Theme.error
                    : (fingerArea.containsMouse || root.scanning ? Theme.cream : Theme.dim)

                MouseArea {
                    id: fingerArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.fingerprint()
                }
            }
        }

        Item {
            width: parent.width
            height: fingerHintText.implicitHeight
            visible: root.scanning && pw.text.length === 0 && root.errorText.length === 0

            Row {
                id: fingerHint
                anchors.centerIn: parent
                spacing: 8

                Item {
                    width: 14
                    height: fingerHintText.implicitHeight

                    GlyphIcon {
                        id: fingerHintIcon
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        name: "fingerprint"
                        stroke: 1.6
                        color: Theme.cream
                        opacity: 1
                    }
                }

                Text {
                    id: fingerHintText
                    text: "touch the sensor"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.letterSpacing: 0.5
                }
            }

            SequentialAnimation {
                running: root.scanning
                loops: Animation.Infinite
                NumberAnimation { target: fingerHintIcon; property: "opacity"; to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { target: fingerHintIcon; property: "opacity"; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                onStopped: fingerHintIcon.opacity = 1
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: root.errorText.length > 0
            text: root.errorText
            color: Theme.error
            font.family: Theme.font
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: !Greetd.available
            text: "greetd is not available"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12
        }
    }
}
