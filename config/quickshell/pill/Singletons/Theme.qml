pragma Singleton
import QtQuick
import Quickshell

/**
 * Pill palette. The values live in the palette file Dyn picks for the current
 * mode: the Nix-built washi identity, the active foot scheme, or the matugen
 * wallpaper set. Text stays in the same place as before -- cream/bright/subtle
 * and friends are palette roles now, not a contrast guard computed here.
 *
 * The translucent veils (hair, sheen, frameBg, threadBg) stay derived from
 * cream so they track whichever source is active.
 */
Singleton {
    readonly property color onGlow: Dyn.onGlow

    readonly property color verm: Dyn.verm
    readonly property color vermLit: Dyn.vermLit
    readonly property color vermDeep: Dyn.vermDeep
    readonly property color cream: Dyn.cream
    readonly property color bright: Dyn.bright
    readonly property color dim: Dyn.dim
    readonly property color cardTop: Dyn.cardTop
    readonly property color cardBot: Dyn.cardBot
    readonly property color border: Dyn.border
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.55)
    readonly property color tileBg: Dyn.tileBg
    readonly property color subtle: Dyn.subtle
    readonly property color faint: Dyn.faint
    readonly property color iconDim: Dyn.iconDim
    readonly property color hair: Qt.alpha(cream, 0.13)
    readonly property color hairSoft: Qt.alpha(cream, 0.08)
    readonly property color sheen: Qt.alpha(cream, 0.07)
    readonly property color vermDim: Dyn.vermDim
    readonly property color vermDimDeep: Dyn.vermDimDeep
    readonly property color vermBurn: Dyn.vermBurn
    readonly property color tickRest: Dyn.tickRest
    readonly property color threadBg: Qt.alpha(cream, 0.13)
    readonly property color flameCore: Dyn.flameCore
    readonly property color flameGlow: Dyn.flameGlow

    /**
     * Flame canvas ramp: literal hex strings (color type won't work), fed
     * directly to Canvas addColorStop/strokeStyle. A color property serializes
     * to #aarrggbb and corrupts the gradient render, so the strings come
     * straight from the palette.
     */
    readonly property string flameInk: Dyn.flameInk
    readonly property string flameEmber: Dyn.flameEmber
    readonly property string flameBurn: Dyn.flameBurn
    readonly property string flameTip: Dyn.flameTip
    readonly property color todayWarm: Dyn.todayWarm
    readonly property color ghost: Dyn.ghost
    readonly property color frameBg: Qt.alpha(cream, 0.055)
    readonly property color frameBorder: Qt.alpha(cream, 0.10)
    readonly property color creamMenu: Qt.alpha(cream, 0.82)
    readonly property real shadowOpacity: 0.5
    /**
     * Snapshot of the system families, not a binding: Qt.fontFamilies() is not
     * notifiable, so a font dropped onto the pill re-registers through
     * refreshFonts() once its FontLoader is ready.
     */
    property var fontFamilies: Qt.fontFamilies()
    function refreshFonts() { fontFamilies = Qt.fontFamilies(); }
    readonly property string font: (Flags.uiFont.length > 0 && fontFamilies.indexOf(Flags.uiFont) >= 0) ? Flags.uiFont : "Inter"
    readonly property string fontJp: "Zen Kaku Gothic New"

    /**
     * MPRIS trackArtists arrives as a JS array from some players and as a
     * plain string from others (Spotify); calling join on the string throws
     * and kills the whole binding. Handles both, falls back to trackArtist.
     */
    function joinArtists(artists, single) {
        if (artists && typeof artists.join === "function" && artists.length > 0)
            return artists.join(", ");
        if (artists && String(artists).length > 0)
            return String(artists);
        return single ? String(single) : "";
    }
}
