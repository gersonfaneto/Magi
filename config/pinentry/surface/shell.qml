pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

/**
 * Quickshell pinentry: the passphrase card for gpg-agent, sudo -A and ssh.
 *
 * The shim (config/pinentry/bin/pinentry.py) owns the pinentry protocol and
 * connects here over a Unix socket in $XDG_RUNTIME_DIR. One line in, one line
 * out: the request carries what the agent wants shown, the answer carries the
 * secret (or a dismissal) and nothing ever lands on disk.
 *
 * Only one card is drawn at a time. Requests that arrive while it is up wait
 * in `queue`, so a second gpg call never steals the prompt from the first.
 */
ShellRoot {
    id: root

    property var queue: []
    property var current: null
    property string targetScreen: ""

    /** modules/wm/pinentry.nix pins XDG_RUNTIME_DIR on the service; the
     *  fallback only keeps a manual run from building a bogus path. */
    readonly property string sockPath:
        (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-pinentry.sock"
    readonly property string focusScreen: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""

    function receive(conn, line) {
        var req;
        try {
            req = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (!req || typeof req !== "object")
            return;
        root.queue = root.queue.concat([{conn: conn, req: req}]);
        root.pump();
    }

    function pump() {
        if (root.current !== null || root.queue.length === 0)
            return;
        var next = root.queue[0];
        root.queue = root.queue.slice(1);
        root.targetScreen = root.focusScreen;
        root.current = next;
    }

    function answer(ok, text) {
        var cur = root.current;
        if (cur === null)
            return;
        root.current = null;
        if (cur.conn && cur.conn.connected) {
            cur.conn.write(JSON.stringify({ok: ok, data: text || ""}) + "\n");
            cur.conn.flush();
            // Hang up first: the client has its line, and closing our end keeps
            // the peer's close from being logged as a socket error.
            cur.conn.connected = false;
        }
        root.pump();
    }

    /** The client went away (cancelled, timed out, or died): drop its card. */
    function drop(conn) {
        root.queue = root.queue.filter(function (item) {
            return item.conn !== conn;
        });
        if (root.current !== null && root.current.conn === conn) {
            root.current = null;
            root.pump();
        }
    }

    SocketServer {
        active: true
        path: root.sockPath

        handler: Socket {
            id: conn

            parser: SplitParser {
                onRead: line => root.receive(conn, line)
            }

            onConnectedChanged: {
                if (!conn.connected)
                    root.drop(conn);
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            readonly property bool target: root.current !== null &&
                (root.targetScreen === "" || root.targetScreen === modelData.name)

            visible: target
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: target ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "pinentry"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            /** Modal: the whole screen takes clicks while the card is up. */
            mask: fullRegion
            Region {
                id: fullRegion
                width: win.width
                height: win.height
            }

            Prompt {
                id: card
                anchors.fill: parent
                s: win.modelData ? win.modelData.height / 1080 : 1
                request: win.target && root.current ? root.current.req : null
                onAccepted: text => root.answer(true, text)
                onDismissed: root.answer(false, "")
            }
        }
    }
}
