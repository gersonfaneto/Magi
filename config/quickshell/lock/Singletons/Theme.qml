pragma Singleton
import QtQuick
import Quickshell

/**
 * Lock palette. Every token comes from the active bundle Dyn reads, so the
 * lock follows washi, a scheme or the wallpaper the same way the pill does.
 */
Singleton {
    readonly property color verm: Dyn.verm
    readonly property color cream: Dyn.cream
    readonly property color bright: Dyn.bright
    readonly property color dim: Dyn.dim
    readonly property string font: "Inter"

    readonly property color fieldBg: Qt.alpha(bright, 0.10)
    readonly property color fieldBorder: Qt.alpha(cream, 0.30)
    readonly property color trackBg: Qt.alpha(cream, 0.16)
    readonly property color error: Dyn.error
}
