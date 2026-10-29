import QtQuick
import "Singletons"

/**
 * Shared morph-surface base for the pill's standard surfaces. Each surface fills
 * the pill body inset by its own margins (scaled by `s`), fades in with the morph
 * as it nears full openness, and is only enabled while open. The host sets `open`,
 * `s` and `morphCloseness`; the surface sets its own `mTop`/`mLeft`/`mRight`/
 * `mBottom` insets. `active` mirrors `open` for the older `onActiveChanged` hooks.
 * `requestClose()` asks the pill to dismiss. Osd and Toast use a different
 * lifecycle and do not derive from this base.
 */
Item {
    id: surface

    property real s: 1
    property bool open: false
    property real morphCloseness: 1

    property real mTop: 0
    property real mLeft: 0
    property real mRight: 0
    property real mBottom: 0

    signal requestClose()

    /**
     * Ame anchor. Each surface declares the flame's form and dock point (in
     * surface-local coords) for its open state; the host maps the point into
     * pill space and feeds the active surface's pair to Ame. Left non-readonly
     * so a deriving surface can re-bind. Base default is off at the centre.
     */
    property string ameForm: "off"
    property point amePoint: Qt.point(width / 2, height / 2)

    readonly property bool active: open

    /**
     * Latched true once the open morph has first settled. The morphCloseness gate
     * is only there for the rest-to-surface open fade. A relayout inside an open
     * surface (a collapsible dropdown snapping its height into implicitHeight) also
     * jumps the pill's target geometry, so closeness craters and the whole surface
     * dims for one frame until the body height Behavior catches up. That one frame
     * is the flicker on the Display, Recorder and Appearance collapsibles. After
     * the surface has settled, hold full opacity and let the body morph alone do
     * the reveal. Reset on close so the next open still fades in.
     */
    property bool settled: false
    onOpenChanged: if (!open) settled = false
    onMorphClosenessChanged: if (open && morphCloseness > 0.92) settled = true

    anchors.fill: parent
    anchors.topMargin: mTop * s
    anchors.leftMargin: mLeft * s
    anchors.rightMargin: mRight * s
    anchors.bottomMargin: mBottom * s

    enabled: open
    opacity: open ? (settled ? 1 : Math.pow(morphCloseness, 1.3)) : 0
    visible: opacity > 0.01

    /**
     * The open fade tracks `morphCloseness` frame by frame. While the morph is
     * running the Behavior is off: retargeting a 240ms fade on every frame made
     * the content arrive a beat after the pill was already open. It comes back
     * for the last settle nudge and for the close fade, where a real animation
     * is what we want.
     */
    Behavior on opacity {
        enabled: !surface.open || surface.settled
        NumberAnimation {
            duration: surface.settled ? Motion.fast : Motion.standard
            easing.type: Motion.easeStandard
        }
    }

    /**
     * Keyboard contract, overridden by surfaces that have rows or tiles. The
     * host calls these through `Pill.navKey`; a false return lets the key fall
     * through to another surface or be ignored. Keeping the defaults here means
     * every surface answers the same calls without boilerplate.
     *
     * `kbStep` is Up/Down, `kbAdjust` Left/Right, `kbPage` PageUp/PageDown,
     * `kbEdge` Ctrl+Home/Ctrl+End, `kbCycle` Tab/Shift+Tab, `kbActivate`
     * Enter/Space, and `kbBack` Escape's one-level pop.
     */
    function kbStep(dir) { return false; }
    function kbAdjust(dir) { return false; }
    function kbPage(dir) { return false; }
    function kbEdge(dir) { return false; }
    function kbCycle(dir) { return false; }
    function kbActivate() { return false; }
    function kbRange() { return false; }
    function kbDelete() { return false; }
    function kbLetter(letter) { return false; }
    function kbBack() { return false; }

    /** Short footer hint for surfaces that opt in; empty leaves the footer out. */
    property string kbHint: ""
}
