//@ pragma UseQApplication

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Singletons"

/**
 * Washi pill top shell. Each monitor carries two layer-shell windows:
 *
 *  - `reserve` is a zero-content strip that only claims an exclusive zone the
 *    height of the rest pill, so tiled windows always sit below the pill even
 *    while it is expanded or a surface is open.
 *  - `overlay` is a full-screen transparent Overlay layer hosting the single
 *    morphing pill anchored at top-centre. The pill never moves windows and is
 *    never re-parented; it just grows in place, so every surface grows out of
 *    the rest pill instead of popping up as a separate panel.
 *
 * Input is routed by the window mask. While the pill is collapsed the mask is
 * the pill rect only, so the rest of the screen clicks through to windows.
 * While the pill is expanded (hovered/pinned) or a surface is open the mask is
 * cleared so the whole layer catches clicks. A backdrop press dismisses, and
 * keyboard focus is taken on demand so Escape closes the open surface.
 */
ShellRoot {
    id: root

    property string openMon: ""
    property string openSurface: ""
    property string peekMon: ""
    property string menuPayload: ""

    /**
     * Session-lock state, written by the lock surface (config/quickshell/lock).
     * While locked the pill is under the lock client, so the audio visualizer
     * has nothing visible to feed; pausing cava saves its FFT and our parsing.
     */
    property bool sessionLocked: false
    readonly property string lockStatePath:
        (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-locked"

    /**
     * True when every monitor's active workspace has a fullscreen client. The
     * pill is retracted on all of them, so cava has no visible consumer either.
     */
    readonly property bool allMonitorsFullscreen: {
        var mons = Hyprland.monitors.values;
        if (mons.length === 0)
            return false;
        for (var i = 0; i < mons.length; i++) {
            var ws = mons[i].activeWorkspace;
            var o = ws ? ws.lastIpcObject : null;
            if (!o || !o.hasfullscreen)
                return false;
        }
        return true;
    }

    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    /** True while MON's active workspace is owned by a fullscreen client. */
    function fullscreenOn(mon) {
        var mons = Hyprland.monitors.values;
        for (var i = 0; i < mons.length; i++) {
            if (mons[i].name !== mon)
                continue;
            var ws = mons[i].activeWorkspace;
            var o = ws ? ws.lastIpcObject : null;
            return o ? !!o.hasfullscreen : false;
        }
        return false;
    }

    /** Whether the dock bar is on screen on MON: enabled, not fullscreen, no game mode. */
    function dockBarShown(mon) {
        return Flags.dockEnabled && !root.fullscreenOn(mon) && !Flags.gameMode;
    }

    Component.onCompleted: {
        refresh();
        Devices.restore();
        void GameMode.active;
        void Sound.eq;
    }

    /**
     * After an update relaunches the shell, raise a one-shot toast naming what
     * landed, so the apply ends in a confirmation instead of a silent restart. The
     * updater drops the marker just before it restarts; the short delay lets the
     * notification server own the bus before we post to it, and the marker is
     * removed as it is read so the toast only ever fires once.
     */
    Timer {
        interval: 2500
        running: true
        onTriggered: updatedToast.running = true
    }
    /**
     * The icon menu hands over megabytes of rows, which will not fit in an IPC
     * argument, so `menuFile` passes a path and this reads it back for it.
     */
    Process {
        id: menuReader
        stdout: StdioCollector {
            id: menuOut
        }
        onExited: (code) => {
            if (code !== 0)
                return;
            const payload = menuOut.text;
            if (payload.length > 0)
                root.openMenu(payload);
        }
    }

    /** The lock surface keeps this file in sync; a stale file is cleared on its startup. */
    FileView {
        path: root.lockStatePath
        watchChanges: true
        blockLoading: true
        printErrors: false
        onLoaded: root.sessionLocked = text().trim() === "1"
        onFileChanged: reload()
        onLoadFailed: root.sessionLocked = false
    }

    Binding {
        target: Cava
        property: "paused"
        value: root.sessionLocked || root.allMonitorsFullscreen
    }
    Process {
        id: updatedToast
        command: ["sh", "-c",
            "m=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/updated\"; [ -f \"$m\" ] || exit 0; "
            + "b=$(cat \"$m\"); rm -f \"$m\"; "
            + "gdbus call --session --dest org.freedesktop.Notifications "
            + "--object-path /org/freedesktop/Notifications "
            + "--method org.freedesktop.Notifications.Notify "
            + "Quickshell 0 '' 'Quickshell updated' \"$b\" '[]' '{}' 5000 >/dev/null 2>&1"]
    }

    PanelWindow {
        id: inhibitWin
        visible: Flags.keepAwake
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "pill-inhibit"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors { top: true; left: true }
        IdleInhibitor { window: inhibitWin; enabled: Flags.keepAwake }
    }

    /**
     * The Wayland IdleInhibitor above only pauses the compositor's own idle
     * (DPMS); hypridle runs its own timer and never sees it, so the lock still
     * fired with keep-awake on. A logind idle inhibitor is the wire hypridle
     * does respect, so hold one for as long as the flag is set.
     */
    Process {
        running: Flags.keepAwake
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Quickshell",
                  "--why=keep awake", "--mode=block", "sleep", "infinity"]
    }

    /**
     * Only these raw events can change what the pill renders (per-monitor
     * active workspace, minimized toplevels, monitor hotplug). Everything
     * else (window drags, resizes, title spam) must not trigger the triple
     * model refresh, which costs three Hyprland IPC round-trips.
     */
    readonly property var refreshEvents: ({
        workspace: true, workspacev2: true,
        createworkspace: true, createworkspacev2: true,
        destroyworkspace: true, destroyworkspacev2: true,
        moveworkspace: true, moveworkspacev2: true,
        renameworkspace: true, activespecial: true,
        focusedmon: true, focusedmonv2: true,
        openwindow: true, closewindow: true,
        movewindow: true, movewindowv2: true,
        fullscreen: true,
        monitoradded: true, monitoraddedv2: true, monitorremoved: true
    })

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.refreshEvents[event.name])
                root.refresh();
        }
    }

    /**
     * An empty monitor argument resolves to the focused monitor here, so the
     * keybind scripts skip their hyprctl+jq round trip and a surface open costs
     * one IPC call instead of three process spawns.
     */
    function toggleSurface(mon, surface) {
        if (!mon || mon.length === 0)
            mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        if (root.openMon === mon && root.openSurface === surface) {
            root.close();
            return;
        }
        root.openMon = mon;
        root.openSurface = surface;
    }

    function close() {
        root.openMon = "";
        root.openSurface = "";
    }

    /**
     * Open the generic menu surface on the focused monitor with PAYLOAD, a JSON
     * request the Menu surface renders (see Menu.qml). Unlike toggleSurface, a
     * second menu call with a fresh payload replaces the open menu instead of
     * closing it, so a caller can hand over a new list without a flicker.
     */
    function openMenu(payload) {
        if (!payload || payload.length === 0) {
            root.close();
            return;
        }
        root.menuPayload = payload;
        root.openMon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        root.openSurface = "menu";
    }

    function peek(mon) {
        root.peekMon = root.peekMon === mon ? "" : mon;
    }

    /**
     * Battery warnings, raised once per threshold crossed while discharging and
     * repeated at the critical level so an unattended laptop still complains.
     * `battNotifiedBelow` is the lowest threshold already announced; plugging in
     * resets it so the next discharge warns afresh.
     */
    property int battNotifiedBelow: 100
    property bool fullBattNotified: false

    function battNote(urgency, summary, body) {
        battNoteProc.command = ["notify-send", "-u", urgency, "-a", "Battery", summary, body];
        battNoteProc.running = true;
    }

    function battCheck() {
        if (!Battery.present)
            return;

        if (!Battery.discharging || Battery.pct > 25) {
            if (root.battRepeatTimer)
                root.battRepeatTimer.stop();
            if (!Battery.discharging)
                root.battNotifiedBelow = 100;
            if (Battery.charging)
                root.fullBattNotified = false;
            return;
        }

        var levels = [[20, false], [15, true], [10, true], [5, true]];
        for (var i = 0; i < levels.length; i++) {
            var cap = levels[i][0];
            var critical = levels[i][1];
            if (Battery.pct <= cap && cap < root.battNotifiedBelow) {
                root.battNotifiedBelow = cap;
                root.battNote(critical ? "critical" : "normal",
                    critical ? "Battery critical" : "Battery low",
                    Battery.pct + "% remaining -- plug in your charger");
            }
        }
        if (Battery.pct <= 15 && root.battRepeatTimer && !root.battRepeatTimer.running)
            root.battRepeatTimer.start();
    }

    Process {
        id: battNoteProc
        running: false
    }

    Timer {
        id: battRepeatTimer
        interval: 120000
        repeat: true
        onTriggered: {
            if (!Battery.present || !Battery.discharging || Battery.pct > 15) {
                root.battRepeatTimer.stop();
                return;
            }
            root.battNote("critical", "Battery critical",
                Battery.pct + "% remaining -- plug in your charger now.");
        }
    }

    Connections {
        target: Battery
        function onPctChanged() { root.battCheck(); }
        function onDischargingChanged() { root.battCheck(); }
        function onChargingChanged() { root.battCheck(); }
    }

    IpcHandler {
        target: "pill"
        function mixer(mon: string): void { root.toggleSurface(mon, "mixer"); }
        function sound(mon: string): void { root.toggleSurface(mon, "sound"); }
        function eq(): void { Sound.setEq(!Sound.eq); }
        function eqMode(name: string): void { Sound.pick(name); }
        function micFilter(): void { Sound.setDenoise(!Sound.denoise); }
        function calendar(mon: string): void { root.toggleSurface(mon, "calendar"); }
        function launcher(mon: string): void { root.toggleSurface(mon, "launcher"); }
        function power(mon: string): void { root.toggleSurface(mon, "power"); }
        function link(mon: string): void { root.toggleSurface(mon, "link"); }
        function battery(mon: string): void { root.toggleSurface(mon, "battery"); }
        function settings(mon: string): void { root.toggleSurface(mon, "settings"); }
        function keybinds(mon: string): void { root.toggleSurface(mon, "keybinds"); }
        function recorder(mon: string): void { root.toggleSurface(mon, "recorder"); }
        /** Open the generic menu surface with a JSON payload (see Menu.qml). */
        function menu(payload: string): void { root.openMenu(payload); }
        /** Same, but read the payload from a file (for lists too big to inline). */
        function menuFile(path: string): void {
            menuReader.command = ["cat", String(path)];
            menuReader.running = true;
        }
        /** The active palette's foreground, for outside tools that tint their own art. */
        function cream(): string { return Theme.cream.toString(); }

        /**
         * Quick-record keybind (SUPER+Print): one button cycles the whole flow with no
         * surface. Recording → stop. Counting down → cancel. A chooser already up
         * on this monitor → dismiss. Otherwise open the standalone source chooser on
         * the focused monitor `mon`, so only that pill renders it.
         */
        function quickRecord(mon: string): void {
            if (ScreenRec.recording) {
                ScreenRec.stop();
            } else if (ScreenRec.counting) {
                ScreenRec.cancel();
            } else if (ScreenRec.quickChoosing) {
                ScreenRec.quickChoosing = false;
                ScreenRec.quickScreenChoosing = false;
            } else {
                ScreenRec.quickMon = mon;
                ScreenRec.quickScreenChoosing = false;
                ScreenRec.quickChoosing = true;
            }
        }
        function gameMode(mon: string): void { Flags.gameMode = !Flags.gameMode; }
        function sysmon(mon: string): void { root.toggleSurface(mon, "sysmon"); }
        function clipboard(mon: string): void { root.toggleSurface(mon, "clipboard"); }
        function wallpaper(mon: string): void { root.toggleSurface(mon, "wallpaper"); }
        function emoji(mon: string): void { root.toggleSurface(mon, "emoji"); }
        function timer(mon: string): void { root.toggleSurface(mon, "timer"); }
        function scratch(mon: string): void { root.toggleSurface(mon, "scratch"); }
        function profile(mon: string): void { root.toggleSurface(mon, "profile"); }
        function dockSettings(mon: string): void { root.toggleSurface(mon, "docksettings"); }
        function media(mon: string): void {
            if (Players.list.length > 0)
                root.toggleSurface(mon, "media");
        }
        function peek(mon: string): void { root.peek(mon); }
        function hide(): void { root.close(); }
        /** SUPER+Escape: dismiss every notification the pill is showing. */
        function notificationsClear(): void { Notifs.clearAll(); }

        /** Opens any surface by name, settings sub-pages included; dev and scripting door. */
        function page(mon: string, name: string): void { root.toggleSurface(mon, name); }

        /**
         * The two halves of the SUPER+M minimize toggle, driven by the
         * minimize-toggle script which has already read the focused window. A
         * desktop window drops into the minimized stash; a window already stashed
         * comes back to the workspace it is handed, so the same key hides and
         * restores. Both target the window by address so they act on the one the
         * user pressed on, not whatever the compositor calls active afterwards.
         */
        function minimizeWindow(addr: string): void {
            Hyprland.dispatch('hl.dsp.window.move({ workspace = "special:minimized", follow = false, window = "address:' + addr + '" })');
        }
        function restoreWindow(arg: string): void {
            var p = arg.split("|");
            if (p.length < 2 || p[0].length === 0)
                return;
            Hyprland.dispatch('hl.dsp.window.move({ workspace = ' + p[1] + ', window = "address:' + p[0] + '" })');
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: reserve
            required property var modelData
            readonly property real s: modelData ? (modelData.height / 1080) * Flags.uiScale : 1
            readonly property real topGap: 8 * Flags.topGap * s
            readonly property real restHeight: 38 * s

            /** Trimming the reserved band below the pill's bottom lets windows climb, so App gap sets the pill-to-window air without touching the desktop gaps_out. */
            readonly property real reservedH: Math.max(0, restHeight + topGap - 12 * (1 - Flags.appGap) * s)

            readonly property real gameBarH: 34 * s

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: Flags.gameMode ? gameBarH : reservedH
            aboveWindows: true

            anchors { top: true; left: true; right: true }
            implicitHeight: Flags.gameMode ? gameBarH : reservedH

            mask: emptyReserve
            Region { id: emptyReserve }
        }
    }

    /**
     * Per-monitor dock, mirroring the pill's two-window split: a bottom reserve
     * claims the bar's band as an exclusive zone while the dock is persistent,
     * and a bottom-anchored overlay hosts the bar itself. With auto-hide on the
     * reserve releases its band and only a thin bottom-centre strip stays live,
     * so the pointer can pull the bar back in.
     */
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockReserve
            required property var modelData
            readonly property real s: modelData ? (modelData.height / 1080) * Flags.dockUiScale : 1
            readonly property real dockH: (Flags.dockMinimal ? 58 : 68) * s
            readonly property real dockLip: 4 * Flags.topGap * s
            readonly property real dockAir: 12 * Flags.dockGap * s
            readonly property real reservedH: dockH + dockLip + dockAir
            readonly property bool barShown: root.dockBarShown(modelData.name)
            readonly property real bandH: (barShown && !Flags.dockAutoHide && !DockState.empty) ? reservedH : 0

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: bandH
            aboveWindows: true

            anchors { bottom: true; left: true; right: true }
            implicitHeight: bandH

            mask: emptyDockReserve
            Region { id: emptyDockReserve }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockWin
            required property var modelData
            readonly property real s: modelData ? (modelData.height / 1080) * Flags.dockUiScale : 1
            readonly property real dockLip: 4 * Flags.topGap * s
            readonly property bool suppressed: !root.dockBarShown(modelData.name)

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "pill-dock"

            anchors { top: true; left: true; right: true; bottom: true }

            mask: (suppressed || dock.empty)
                ? dockHiddenRegion
                : (Flags.dockAutoHide ? ((dock.revealSession || dock.hovered) ? dockRevealUnion : dockRevealRegion)
                    : (dock.hovered || dock.previewOpen ? dockPopBand : dockRegion))

            Region { id: dockHiddenRegion }

            Region {
                id: dockRevealRegion
                readonly property real revealW: dock.width + 12 * dock.s
                readonly property real revealH: 10 * dock.s
                x: Math.max(0, dockWin.width / 2 - revealW / 2)
                y: dockWin.height - revealH
                width: revealW
                height: dockWin.height - y
            }

            Region {
                id: dockRegion
                x: dock.x
                y: dock.y
                width: dock.width
                height: dock.height
            }

            Region {
                id: dockPopBand
                readonly property bool deep: dock.previewOpen
                readonly property real bandH: (deep ? 190 : 44) * dock.s
                readonly property real sideW: (deep ? 100 : 6) * dock.s
                x: Math.max(0, dock.x - sideW)
                y: Math.max(0, dock.y - bandH)
                width: dock.width + sideW * 2
                height: bandH + dock.height
            }

            Region {
                id: dockRevealUnion
                x: dockRevealRegion.x
                y: dockRevealRegion.y
                width: dockRevealRegion.width
                height: dockRevealRegion.height
                Region {
                    x: dockPopBand.x
                    y: dockPopBand.y
                    width: dockPopBand.width
                    height: dockPopBand.height
                }
            }

            DockBar {
                id: dock
                s: dockWin.s
                screenName: dockWin.modelData.name
                anchors.bottom: parent.bottom
                anchors.bottomMargin: dockWin.dockLip
                anchors.horizontalCenter: parent.horizontalCenter
                transform: Translate {
                    y: (dock.hidden || dockWin.suppressed) ? (dock.height + dockWin.dockLip + 8 * dock.s) : 0
                    Behavior on y {
                        NumberAnimation {
                            duration: Motion.dockMorph
                            easing.type: Motion.dockEase
                            easing.bezierCurve: Motion.morphCurve
                        }
                    }
                }
                onSettingsRequested: root.toggleSurface(dockWin.modelData.name, "docksettings")
            }

            HoverHandler {
                onHoveredChanged: dock.hovered = hovered
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlay
            required property var modelData
            readonly property real s: modelData ? (modelData.height / 1080) * Flags.uiScale : 1
            readonly property real topGap: 8 * Flags.topGap * s
            readonly property string surface: root.openMon === modelData.name ? root.openSurface : ""
            readonly property bool surfaceOpen: surface.length > 0
            readonly property bool modal: pill.authPending ? false : (surfaceOpen || pill.held || pill.quickChoosing)

            /**
             * True while this monitor's active workspace reports a fullscreen
             * client. The pill retracts off the top edge and the layer is
             * click-through so fullscreen content owns the screen, until a
             * surface or a peek summons it back over the content.
             */
            readonly property bool monFullscreen: {
                var mons = Hyprland.monitors.values;
                for (var i = 0; i < mons.length; i++) {
                    if (mons[i].name === modelData.name) {
                        var ws = mons[i].activeWorkspace;
                        var o = ws ? ws.lastIpcObject : null;
                        return o ? !!o.hasfullscreen : false;
                    }
                }
                return false;
            }
            readonly property bool summoned: modal || root.peekMon === modelData.name
            readonly property bool pillHidden: monFullscreen && !summoned

            onMonFullscreenChanged: if (monFullscreen) {
                if (root.openMon === modelData.name) root.close();
                if (root.peekMon === modelData.name) root.peekMon = "";
                pill.pinned = false;
            }

            /** Rest, hover, toasts and OSDs fit a top band; the layer only spans the screen while a surface or tall morph needs it. */
            readonly property real bandH: Math.ceil(topGap + 200 * s + slot.pad)
            readonly property bool tall: modal || topGap + Math.max(pill.height, pill.targetH) + slot.pad > bandH

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: ((surfaceOpen || pill.quickChoosing) && !pill.authPending) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "pill"

            anchors { top: true; left: true; right: true }
            implicitHeight: tall ? modelData.height : bandH

            mask: modal ? fullRegion : (pillHidden ? hiddenRegion : pillRegion)
            Region { id: hiddenRegion }
            Region {
                id: pillRegion
                readonly property real baseW: Math.max(pill.width, pill.targetW)
                x: slot.x + pill.x + (pill.width - baseW) / 2
                y: slot.y + pill.y
                width: baseW + pill.inputPadRight
                height: Math.max(pill.height, pill.targetH)
            }
            Region {
                id: fullRegion
                width: overlay.width
                height: overlay.height
            }

            MouseArea {
                anchors.fill: parent
                enabled: overlay.modal
                acceptedButtons: Qt.AllButtons
                onPressed: (mouse) => {
                    if (pill.menuOpen) {
                        pill.menuCancel();
                        return;
                    }
                    if (pill.quickChoosing) {
                        ScreenRec.quickChoosing = false;
                        ScreenRec.quickScreenChoosing = false;
                    } else if (overlay.surfaceOpen) {
                        var inside = mouse.x >= pillRegion.x && mouse.x <= pillRegion.x + pillRegion.width
                            && mouse.y >= pillRegion.y && mouse.y <= pillRegion.y + pillRegion.height;
                        if (!inside)
                            root.close();
                        else if (mouse.y <= pillRegion.y + 40 * pill.s)
                            pill.surfaceBack();
                    } else {
                        pill.pinned = false;
                        root.peekMon = "";
                    }
                }
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: overlay.surfaceOpen || pill.quickChoosing

                HoverHandler {
                    onHoveredChanged: pill.hovered = hovered
                }

                /**
                 * True while a TextInput/TextField owns focus. Such a field
                 * handles arrows, Enter and typing itself; navigation must not
                 * also move the surface cursor underneath it.
                 */
                readonly property bool textFocused: {
                    const it = focusScope.activeFocusItem;
                    return !!it && it.cursorPosition !== undefined && it.text !== undefined;
                }

                /**
                 * All keyboard routing goes through `Pill.navKey`, which asks
                 * the open surface's PillSurface contract. A search field owns
                 * its keys first; this scope sees whatever bubbles past it.
                 */
                Keys.onPressed: (e) => {
                    var alt = (e.modifiers & Qt.AltModifier) !== 0;
                    var ctrl = (e.modifiers & Qt.ControlModifier) !== 0;

                    // Ctrl+/ toggles the keyboard reference from anywhere.
                    if (ctrl && (e.key === Qt.Key_Slash || e.key === Qt.Key_Question)
                        && !pill.keybindsListening) {
                        if (pill.keysOpen)
                            pill.requestClose();
                        else
                            pill.requestSurface("keys");
                        e.accepted = true;
                        return;
                    }

                    // Bare typing over the wallpaper strip opens its search.
                    if (pill.wallpaperOpen && !pill.wallpaperSearching
                        && !ctrl && !alt
                        && e.text.length === 1 && e.text > " ") {
                        pill.wallpaperType(e.text);
                        e.accepted = true;
                        return;
                    }

                    if (e.key === Qt.Key_Escape) {
                        if (pill.quickChoosing) {
                            ScreenRec.quickChoosing = false;
                            ScreenRec.quickScreenChoosing = false;
                            e.accepted = true;
                            return;
                        }
                        // The keybinds chord catcher has focus and owns Escape.
                        if (pill.keybindsListening)
                            return;
                        pill.back();
                        e.accepted = true;
                        return;
                    }

                    if (focusScope.textFocused)
                        return;

                    // A held Enter/Space must not re-fire an action; the power
                    // surface reads the release to drain a destructive hold.
                    if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                        && e.isAutoRepeat) {
                        e.accepted = true;
                        return;
                    }

                    if (pill.navKey(e.key, e.modifiers))
                        e.accepted = true;
                }
                Keys.onReleased: (e) => {
                    if (e.isAutoRepeat)
                        return;
                    if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                        && pill.powerOpen) {
                        pill.powerRelease();
                        e.accepted = true;
                    }
                }

                /**
                 * Slot the pill rests in. While a toast is dragged the slot
                 * becomes a soft-edged mask: the pill slides against an invisible
                 * wall and dissolves at the edge it leaves through instead of
                 * getting cut. The fade lives in the padding outside the pill's
                 * resting footprint, so an unmoved pill is never touched by it.
                 */
                Item {
                    id: slot
                    readonly property real pad: 56 * overlay.s
                    readonly property bool swiping: pill.swipeX !== 0 || pill.swipeY !== 0
                    anchors.top: parent.top
                    anchors.topMargin: (pill.mode === "game" ? 0 : overlay.topGap) - pad
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: pill.width + 2 * pad
                    height: pill.height + 2 * pad

                    Behavior on anchors.topMargin {
                        NumberAnimation {
                            duration: Motion.morph
                            easing.type: Motion.easeMorph
                            easing.bezierCurve: Motion.morphCurve
                        }
                    }

                    layer.enabled: swiping
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: wall
                    }

                    Item {
                        id: wall
                        width: slot.width
                        height: slot.height
                        visible: false
                        layer.enabled: true

                        Rectangle {
                            id: wallRect
                            anchors.fill: parent
                            readonly property bool sideways: pill.swipeX !== 0
                            readonly property bool leftward: pill.swipeX < 0
                            readonly property real edge: slot.pad / (sideways ? slot.width : slot.height)
                            gradient: Gradient {
                                orientation: wallRect.sideways ? Gradient.Horizontal : Gradient.Vertical
                                GradientStop { position: 0.0; color: wallRect.sideways && !wallRect.leftward ? "white" : "transparent" }
                                GradientStop { position: wallRect.edge; color: "white" }
                                GradientStop { position: 1 - wallRect.edge; color: "white" }
                                GradientStop { position: 1.0; color: wallRect.sideways && wallRect.leftward ? "white" : "transparent" }
                            }
                        }
                    }

                Pill {
                    id: pill
                    anchors.top: parent.top
                    anchors.topMargin: slot.pad
                    anchors.horizontalCenter: parent.horizontalCenter
                    s: overlay.s
                    screenName: overlay.modelData.name
                    barWindow: overlay
                    surface: overlay.surface
                    menuPayload: root.menuPayload
                    forcePinned: root.peekMon === overlay.modelData.name

                    opacity: overlay.pillHidden ? 0 : pill.swipeFade
                    Behavior on opacity {
                        enabled: !slot.swiping
                        NumberAnimation {
                            duration: Motion.morph
                            easing.type: Motion.easeMorph
                            easing.bezierCurve: Motion.morphCurve
                        }
                    }
                    transform: [
                        Translate { x: pill.swipeX; y: pill.swipeY },
                        Translate {
                            y: overlay.pillHidden ? -(pill.height + overlay.topGap) : 0
                            Behavior on y {
                                NumberAnimation {
                                    duration: Motion.morph
                                    easing.type: Motion.easeMorph
                                    easing.bezierCurve: Motion.morphCurve
                                }
                            }
                        }
                    ]

                    onRequestSurface: (name) => root.toggleSurface(overlay.modelData.name, name)
                    onRequestClose: root.close()
                }
                }
            }

            onSurfaceOpenChanged: if (surfaceOpen) focusScope.forceActiveFocus()

            Connections {
                target: pill
                function onQuickChoosingChanged() {
                    if (pill.quickChoosing)
                        focusScope.forceActiveFocus();
                }
                function onWallpaperSearchingChanged() {
                    if (!pill.wallpaperSearching && overlay.surfaceOpen)
                        focusScope.forceActiveFocus();
                }
                function onKeybindsListeningChanged() {
                    if (!pill.keybindsListening && overlay.surfaceOpen)
                        focusScope.forceActiveFocus();
                }
            }
        }
    }
}
