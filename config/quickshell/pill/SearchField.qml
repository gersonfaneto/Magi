import QtQuick
import QtQuick.Controls
import "Singletons"

Item {
    id: root

    property real s: 1
    property string kanji: ""
    property string placeholder: ""
    property string counterText: ""
    property real kanjiSize: 16
    property real fontSize: 15
    property real gap: 10
    property real lead: 0
    property real trail: 10
    property real lineGap: 2
    property real restOpacity: 0
    property bool showCursor: false
    /** TextInput.Normal, or TextInput.Password to mask the field. */
    property int echoMode: TextInput.Normal
    /** Off leaves Escape to the pill's own back and close handling. */
    property bool catchEscape: true

    /**
     * Map Left/Right to the moved() signal instead of text-cursor motion. For a
     * horizontal result strip the arrows should page the strip; without this the
     * field swallows them until the caret sits at a text boundary, so navigation
     * stalls mid-query.
     */
    property bool horizontalNav: false
    readonly property alias input: field
    property alias text: field.text
    default property alias rightContent: rightSlot.data

    signal moved(int delta)
    signal paged(int delta)
    signal jumped(int edge)
    signal cycled(int delta)
    signal numbered(int n)
    signal accepted()
    signal dismissed()
    signal keyPressed(var event)

    height: 30 * s

    Text {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.lead * root.s
        visible: Flags.showGlyphs
        width: Flags.showGlyphs ? implicitWidth : 0
        text: root.kanji
        color: Theme.dim
        font.family: Theme.fontJp
        font.weight: Font.Medium
        font.pixelSize: root.kanjiSize * root.s
    }

    Component {
        id: noCursor
        Item {}
    }

    TextField {
        id: field
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: glyph.right
        anchors.leftMargin: Flags.showGlyphs ? root.gap * root.s : root.lead * root.s
        anchors.right: counter.left
        anchors.rightMargin: root.trail * root.s
        background: null
        padding: 0
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: root.fontSize * root.s
        placeholderText: root.placeholder
        placeholderTextColor: Theme.faint
        echoMode: root.echoMode
        selectByMouse: true
        selectionColor: Theme.verm
        cursorDelegate: root.showCursor ? null : noCursor
        Keys.onPressed: (e) => {
            root.keyPressed(e);
            if (e.accepted)
                return;
            var ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
            var alt = (e.modifiers & Qt.AltModifier) !== 0;
            var shift = (e.modifiers & Qt.ShiftModifier) !== 0;
            if (e.key === Qt.Key_Up) {
                root.moved(-1);
            } else if (e.key === Qt.Key_Down) {
                root.moved(1);
            } else if (ctrl && e.key === Qt.Key_P) {
                root.moved(-1);
            } else if (ctrl && e.key === Qt.Key_N) {
                root.moved(1);
            } else if (e.key === Qt.Key_PageUp) {
                root.paged(-1);
            } else if (e.key === Qt.Key_PageDown) {
                root.paged(1);
            } else if (ctrl && e.key === Qt.Key_Home) {
                root.jumped(-1);
            } else if (ctrl && e.key === Qt.Key_End) {
                root.jumped(1);
            } else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
                root.cycled((e.key === Qt.Key_Backtab || shift) ? -1 : 1);
            } else if (alt && e.key >= Qt.Key_1 && e.key <= Qt.Key_9) {
                root.numbered(e.key - Qt.Key_0);
            } else if (root.horizontalNav && (e.key === Qt.Key_Left || e.key === Qt.Key_Right)) {
                root.moved(e.key === Qt.Key_Right ? 1 : -1);
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                root.accepted();
            } else if (root.catchEscape && e.key === Qt.Key_Escape) {
                root.dismissed();
            } else {
                return;
            }
            e.accepted = true;
        }
    }

    Rectangle {
        anchors.left: field.left
        anchors.right: field.right
        anchors.top: field.bottom
        anchors.topMargin: root.lineGap * root.s
        height: 1
        color: Theme.faint
        opacity: field.activeFocus ? 0.7 : root.restOpacity
        Behavior on opacity { NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard } }
    }

    Text {
        id: counter
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: rightSlot.left
        anchors.rightMargin: rightSlot.width > 0 ? 10 * root.s : 0
        text: root.counterText
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
        font.features: { "tnum": 1 }
    }

    Item {
        id: rightSlot
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        width: childrenRect.width
        height: parent.height
    }
}
