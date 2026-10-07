# lib/magi/menu.janet
#
# An API for the Quickshell pill's generic menu surface
# (config/quickshell/pill/Menu.qml). It replaces the old rofi API: instead of
# spawning rofi and reading its dmenu output, a script hands the surface a JSON
# payload over `qs ipc` and blocks on the result file the surface writes when a
# row is picked -- or when the menu is dismissed, so Escape always returns.
#
# The surface owns no data, so every menu's logic stays in the script that calls
# this, and the payload is just rows plus a place to put the answer.

(use ./lib)
(import ./sys :as sys)
(import spork/json :as json)

(var *seq* 0)

(defn- result-path []
  (path :runtime (string/format "menu-%d-%d" (os/getpid) (++ *seq*))))

(defn- row
  ``Normalize ITEM into a menu row. A table is taken as-is (its :label defaults
  to its :data); anything else becomes a label-and-data string.``
  [item]
  (if (dictionary? item)
    (merge {:label (string (or (item :label) (item :data) ""))} item)
    {:label (string item) :data item}))

(defn- open
  ``Show the surface with PAYLOAD (written to a file beside FILE, as lists can
  outgrow an IPC argument) and block until the result file appears. Returns its
  contents, or nil if the caller waited an hour (the shell is gone).``
  [payload file]
  (def payload-file (string file ".json"))
  (spit payload-file payload)
  (defer (ignore-errors (os/rm payload-file))
    (unless (zero? (os/execute ["qs" "-c" "pill" "ipc" "call" "pill" "menuFile" payload-file] :p))
      (abort "Could not open the menu; is the Quickshell pill running?"))
    # 20 polls a second for an hour: the surface writes the result as soon as
    # it closes, so the wait only ever runs this long if the shell died.
    (var waited 0)
    (while (and (not (os/stat file :mode)) (< waited 72000))
      (ev/sleep 0.05)
      (++ waited))
    (when (os/stat file :mode)
      (slurp file))))

(defn- decode [raw]
  (def res (json/decode raw :keywords true))
  (when (res :ok)
    (res :data)))

(defn pick
  ``Show ITEMS in the menu surface and return the picked row's :data, or nil if
  the menu was dismissed. ITEMS is a sequence of tables; each may carry a :label,
  :desc, :icon (an icon name or a path to an image), :glyph (a baked glyph name),
  :data (handed back verbatim) and :accent (highlight the row). TITLE names the
  menu, GLYPH is its kanji, PROMPT turns on the search field, and MESSAGE shows a
  line under the header.``
  [items &named title glyph prompt message]
  (def file (result-path))
  (defer (ignore-errors (os/rm file))
    (if-let [raw (open
                   (json/encode
                     {:title (or title "MENU")
                      :glyph glyph
                      :prompt prompt
                      :message message
                      :items (map row items)
                      :resultPath file})
                   file)]
      (decode raw))))

(defn read
  ``Prompt for one line of text in the menu surface; return it, or nil if the
  prompt was dismissed. PLACEHOLDER shows while the field is empty, PASSWORD
  masks what is typed.``
  [&named title placeholder password]
  (def file (result-path))
  (defer (ignore-errors (os/rm file))
    (if-let [raw (open
                   (json/encode
                     {:title (or title "INPUT")
                      :glyph "問"
                      :input true
                      :password password
                      :prompt placeholder
                      :resultPath file})
                   file)]
      (decode raw))))

(defn prompt
  ``Ask QUESTION with a yes and a no row; return true, false, or nil if the menu
  was dismissed.``
  [question &named yes no]
  (pick [{:label (or yes "Yes") :data true :accent true}
         {:label (or no "No") :data false}]
        :title "CONFIRM" :message question))

(defn notice
  ``Show MESSAGE as a notification; the pill owns org.freedesktop.Notifications.
  Accepts fmt-style ARGS.``
  [message & args]
  (sys/notify (fmt message ;args)))

(defn error
  ``Show MESSAGE as an error notification, then raise it. Accepts fmt-style
  ARGS.``
  [message & args]
  (sys/toast :error (fmt message ;args) :icon "dialog-error")
  (errorf message ;args))
