pragma Singleton
import QtQuick
import Quickshell

/**
 * Greeter palette. The login screen runs as the `greeter` user before any
 * session exists, so it cannot read the user's flags or generated theme files;
 * this is the static washi identity the shell falls back to, duplicated here
 * rather than imported so the greeter config stays self-contained.
 */
Singleton {
    readonly property color verm: "#c0442b"
    readonly property color cream: "#e6d6cb"
    readonly property color bright: "#fff6f0"
    readonly property color dim: "#8a7d74"
    readonly property color error: "#e0563b"
    readonly property string font: "Inter"

    readonly property color fieldBg: Qt.rgba(1, 0.96, 0.94, 0.10)
    readonly property color fieldBorder: Qt.rgba(230 / 255, 214 / 255, 203 / 255, 0.30)
}
