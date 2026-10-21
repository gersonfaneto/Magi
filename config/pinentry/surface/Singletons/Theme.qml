pragma Singleton
import QtQuick
import Quickshell

/**
 * Passphrase card tokens. Everything comes from Dyn's palette bundle, so the
 * card matches the lock's capsule and the pill's panels whichever scheme,
 * wallpaper or fixed identity is active.
 */
Singleton {
    readonly property color verm: Dyn.verm
    readonly property color vermLit: Dyn.vermLit
    readonly property color vermDeep: Dyn.vermDeep
    readonly property color cream: Dyn.cream
    readonly property color bright: Dyn.bright
    readonly property color subtle: Dyn.subtle
    readonly property color dim: Dyn.dim
    readonly property color faint: Dyn.faint
    readonly property color cardTop: Dyn.cardTop
    readonly property color cardBot: Dyn.cardBot
    readonly property color border: Dyn.border
    readonly property color error: Dyn.vermLit

    readonly property color fieldBg: Qt.alpha(cream, 0.10)
    readonly property color fieldBorder: Qt.alpha(cream, 0.30)
    readonly property color trackBg: Qt.alpha(cream, 0.16)
    readonly property color hair: Qt.alpha(cream, 0.10)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.6)

    readonly property string font: "Inter"
    readonly property string fontJp: "Zen Kaku Gothic New"
}
