pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "Singletons"

/**
 * Quickshell greeter: one plain xdg-toplevel, run by cage as the greetd
 * default session (see modules/wm/greeter.nix).
 *
 * cage has no wlr-layer-shell implementation, so a PanelWindow would never be
 * mapped (black screen with just the cursor). A FloatingWindow is a regular
 * toplevel, which cage maximizes to the output.
 */
ShellRoot {
    id: root

    FloatingWindow {
        id: win
        readonly property var scr: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

        title: "Login"
        screen: win.scr
        color: "#14100e"
        visible: true
        implicitWidth: win.scr ? win.scr.width : 1920
        implicitHeight: win.scr ? win.scr.height : 1080
        fullscreen: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#14100e" }
                GradientStop { position: 0.55; color: "#1e1714" }
                GradientStop { position: 1.0; color: "#0a0807" }
            }
        }

        /** The same ember wash the lock uses, without a live wallpaper to sample. */
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.85
            height: width
            radius: width / 2
            color: Theme.verm
            opacity: 0.045
        }

        Greeter {
            anchors.fill: parent
        }
    }
}
