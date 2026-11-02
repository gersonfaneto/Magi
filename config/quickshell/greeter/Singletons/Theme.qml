pragma Singleton
import QtQuick
import Quickshell

/**
 * Greeter palette. The login screen runs as the `greeter` user before any
 * session exists, so it cannot read the user's flags or generated theme files;
 * this is the static default scheme (nano dark), duplicated here rather than
 * imported so the greeter config stays self-contained.
 */
Singleton {
    readonly property color verm: "#81a1c0"
    readonly property color cream: "#cbced2"
    readonly property color bright: "#dddfe2"
    readonly property color dim: "#898d95"
    readonly property color error: "#d08770"
    readonly property string font: "Inter"

    readonly property color fieldBg: Qt.rgba(203 / 255, 206 / 255, 210 / 255, 0.10)
    readonly property color fieldBorder: Qt.rgba(203 / 255, 206 / 255, 210 / 255, 0.30)
}
