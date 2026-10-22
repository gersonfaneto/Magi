pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property real mult: Flags.reduceMotion ? 0.4 : 1
    /* Tuned snappy: the old 420/300/260 set read as a lag on repeat use. */
    readonly property int fast:     Math.round(110 * mult)
    readonly property int standard: Math.round(240 * mult)
    readonly property int morph:    Math.round(320 * mult)
    readonly property int shapeshift: Math.round(640 * mult)
    readonly property int glide:    Math.round(210 * mult)
    readonly property int heat:     Math.round(800 * mult)
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeMorph:    Easing.BezierSpline

    /**
     * Liquid morph curve, cubic-bezier(0.16, 1, 0.3, 1). Front-loaded like an
     * exponential chase but with a long, visible settle tail. Use with
     * easeMorph (BezierSpline).
     */
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
    readonly property real rSmall: 7
    readonly property real rTile:  13

    /** Looping scan/pairing breath pulse. */
    readonly property int pulse: Math.round(320 * mult)
}
