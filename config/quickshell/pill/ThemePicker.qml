pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "Singletons"
import "lib/nav.js" as Nav

/**
 * 彩 THEME sub-surface: every curated scheme/tone pair as a searchable row with
 * a live palette swatch. Picking a row runs theme.py set, so the same renderer
 * that the keybinds and login service use applies the palette everywhere and
 * selects that scheme's first bundled wallpaper. The wallpaper strip's theme
 * chip follows the active scheme, so this list is also the front door to the
 * rest of a theme's bundled wallpapers.
 */
SettingsSurface {
    id: root

    implicitHeight: content.implicitHeight
    rows: []

    property string query: ""
    property int focusIndex: 0
    property point lastPointer: Qt.point(-1, -1)
    property var pendingTheme: null

    function labelFor(name) {
        var parts = String(name).split(/[-_ ]+/);
        var out = [];
        for (var i = 0; i < parts.length; i++) {
            var word = parts[i];
            if (word.length > 0)
                out.push(word.charAt(0).toUpperCase() + word.slice(1));
        }
        return out.join(" ");
    }

    function wallpaperCount(name) {
        var n = 0;
        for (var i = 0; i < Walls.entries.length; i++)
            if (Walls.entries[i].theme === name)
                n++;
        return n;
    }

    readonly property var variants: {
        var q = root.query.trim().toLowerCase();
        var out = [];
        for (var i = 0; i < Themes.themes.length; i++) {
            var theme = Themes.themes[i];
            var label = root.labelFor(theme.name);
            for (var j = 0; j < theme.tones.length; j++) {
                var tone = theme.tones[j];
                var hay = (theme.name + " " + label + " " + tone.tone).toLowerCase();
                if (q.length > 0 && hay.indexOf(q) < 0)
                    continue;
                out.push({
                    scheme: theme.name,
                    tone: tone.tone,
                    label: label,
                    preview: tone,
                    editor: theme.editor
                });
            }
        }
        out.sort(function (a, b) {
            var al = (a.label + " " + a.tone).toLowerCase();
            var bl = (b.label + " " + b.tone).toLowerCase();
            return al < bl ? -1 : (al > bl ? 1 : 0);
        });
        return out;
    }

    function currentIndex() {
        for (var i = 0; i < root.variants.length; i++) {
            var v = root.variants[i];
            if (v.scheme === Flags.scheme && v.tone === Flags.bg)
                return i;
        }
        return 0;
    }

    function centerOnCurrent() {
        if (root.variants.length === 0) {
            root.focusIndex = 0;
            return;
        }
        root.focusIndex = root.currentIndex();
        list.positionViewAtIndex(root.focusIndex, ListView.Contain);
    }

    function move(dir) {
        if (root.variants.length === 0)
            return false;
        root.focusIndex = Nav.step(root.focusIndex, root.variants.length, dir, true);
        list.positionViewAtIndex(root.focusIndex, ListView.Contain);
        return true;
    }

    readonly property int pageRows: Math.max(1, Math.floor(list.height / (42 * root.s)))

    function page(dir) {
        if (root.variants.length === 0)
            return false;
        root.focusIndex = Nav.page(root.focusIndex, root.variants.length, dir, pageRows, true);
        list.positionViewAtIndex(root.focusIndex, ListView.Contain);
        return true;
    }

    function edge(dir) {
        if (root.variants.length === 0)
            return false;
        root.focusIndex = Nav.edge(root.variants.length, dir);
        list.positionViewAtIndex(root.focusIndex, ListView.Contain);
        return true;
    }

    function runTheme(args) {
        if (themeProc.running) {
            pendingTheme = args;
            return;
        }
        themeProc.command = ["sh", "-c", "python3 \"$HOME/.config/hypr/scripts/theme.py\" \"$@\"", "sh"].concat(args);
        themeProc.running = true;
    }

    function pick(variant) {
        runTheme(["set", variant.scheme, variant.tone]);
    }

    function activate() {
        if (root.focusIndex < 0 || root.focusIndex >= root.variants.length)
            return false;
        root.pick(root.variants[root.focusIndex]);
        return true;
    }

    function back() {
        if (root.query.length > 0 || searchField.text.length > 0) {
            searchField.text = "";
            root.query = "";
            root.focusIndex = 0;
            return true;
        }
        return false;
    }

    function kbStep(dir) { return move(dir); }
    function kbPage(dir) { return page(dir); }
    function kbEdge(dir) { return edge(dir); }
    function kbCycle(dir) { return move(dir); }
    function kbActivate() { return activate(); }
    function kbBack() { return back(); }

    onActiveChanged: {
        if (active) {
            Themes.refresh();
            query = "";
            searchField.text = "";
            Qt.callLater(centerOnCurrent);
            Qt.callLater(searchField.input.forceActiveFocus);
        } else {
            query = "";
            searchField.text = "";
        }
    }

    Connections {
        target: Themes
        function onThemesChanged() {
            if (root.active)
                Qt.callLater(root.centerOnCurrent);
        }
    }

    Process {
        id: themeProc
        onExited: {
            if (root.pendingTheme) {
                var next = root.pendingTheme;
                root.pendingTheme = null;
                root.runTheme(next);
            }
        }
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            glyph: "彩"
            title: "THEME"
            showBack: true
        }

        Item { width: 1; height: 10 * root.s }

        SearchField {
            id: searchField
            width: parent.width
            height: 28 * root.s
            s: root.s
            kanji: "探"
            placeholder: "search themes"
            kanjiSize: 15
            fontSize: 13
            gap: 9
            lead: 4
            trail: 4
            lineGap: 3
            restOpacity: 0.18
            showCursor: true
            catchEscape: false
            onTextChanged: {
                root.query = text;
                root.focusIndex = 0;
            }
            onMoved: (d) => root.move(d)
            onPaged: (d) => root.page(d)
            onJumped: (d) => root.edge(d)
            onCycled: (d) => root.move(d)
            onAccepted: root.activate()
        }

        Item { width: 1; height: 8 * root.s }

        Item {
            id: listFrame
            width: parent.width
            height: Math.min(list.contentHeight, 300 * root.s)

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.variants

                delegate: Item {
                    id: trow
                    required property int index
                    required property var modelData

                    readonly property bool selected: Flags.scheme === trow.modelData.scheme
                        && Flags.bg === trow.modelData.tone
                    readonly property bool focused: root.focusIndex === trow.index
                    readonly property int wallpapers: root.wallpaperCount(trow.modelData.scheme)

                    width: ListView.view.width
                    height: 42 * root.s

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: (m) => {
                            var g = rowArea.mapToItem(null, m.x, m.y);
                            if (g.x !== root.lastPointer.x || g.y !== root.lastPointer.y) {
                                root.lastPointer = Qt.point(g.x, g.y);
                                root.focusIndex = trow.index;
                            }
                        }
                        onClicked: root.pick(trow.modelData)
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2 * root.s
                        anchors.bottomMargin: 2 * root.s
                        radius: 9 * root.s
                        color: trow.selected
                            ? Qt.alpha(Theme.vermLit, 0.14)
                            : (trow.focused ? Theme.frameBg : "transparent")
                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                    }

                    Rectangle {
                        id: swatch
                        anchors.left: parent.left
                        anchors.leftMargin: 12 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 46 * root.s
                        height: 26 * root.s
                        radius: 5 * root.s
                        color: trow.modelData.preview.background
                        border.width: 1
                        border.color: Qt.alpha(Theme.cream, 0.16)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 5 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3 * root.s
                            height: parent.height - 10 * root.s
                            radius: width / 2
                            color: trow.modelData.preview.primary
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 5 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6 * root.s
                            height: 6 * root.s
                            radius: width / 2
                            color: trow.modelData.preview.cream
                        }
                    }

                    Column {
                        anchors.left: swatch.right
                        anchors.leftMargin: 10 * root.s
                        anchors.right: tick.left
                        anchors.rightMargin: 10 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * root.s

                        Text {
                            width: parent.width
                            text: trow.modelData.label
                            color: trow.selected ? Theme.vermLit : Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 12.5 * root.s
                            font.weight: trow.selected ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: trow.modelData.tone + " / " + trow.wallpapers + " wallpapers"
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 9.5 * root.s
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: tick
                        anchors.right: parent.right
                        anchors.rightMargin: 14 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        visible: trow.selected
                        width: 6 * root.s
                        height: 6 * root.s
                        radius: width / 2
                        color: Theme.vermLit
                    }
                }
            }

            WheelScroller {
                anchors.fill: parent
                s: root.s
                flick: list
            }
        }

        Text {
            width: parent.width
            visible: root.variants.length === 0
            text: Themes.error.length > 0 ? "theme catalog unavailable" : (Themes.loaded ? "no themes match" : "loading themes")
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10.5 * root.s
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
