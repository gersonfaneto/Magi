# lib/magi/menu.janet
#
# An API for `fsel --dmenu` (config/fsel). A script hands fsel a list of rows
# and blocks until a row is picked -- or until the menu is dismissed, so Escape
# always returns. fsel draws on /dev/tty and writes the answer to stdout, so a
# menu must run inside a terminal (`foot --app-id=magi-menu -e magi @menu ...`).
#
# The surface owns no data, so every menu's logic stays in the script that calls
# this. Rows travel as `label<TAB>desc<TAB>id`; only the id comes back, so the
# caller's :data is handed over verbatim and never round-trips through the menu.

(use ./lib)
(import ./sys :as sys)
(import spork/json :as json)

(def- *delimiter* "\t")

(defn- shell-quote
  ``Single-quote S for sh. Used for the file paths this module generates, which
  never contain newlines.``
  [s]
  (string "'" (string/replace-all "'" "'\\''" s) "'"))

(defn- run
  ``Run the fsel COMMAND with stdin from IN and stdout into OUT. fsel paints on
  stderr, so it stays attached to the caller's terminal; returns its exit code.``
  [command in out]
  (def script
    (string/format "exec %s < %s > %s"
                   command (shell-quote in) (shell-quote out)))
  (os/execute ["sh" "-c" script] :p))

(defn- temp [suffix]
  (def dir (path :runtime))
  (unless (path/directory? dir)
    (os/mkdir dir))
  (path :runtime (string/format "menu-%d-%s" (os/getpid) suffix)))

(defn- slurp-stripped [file]
  (string/trimr (slurp file) "\r\n"))

(defn- row
  ``Normalize ITEM into a menu row. A table is taken as-is (its :label defaults
  to its :data); anything else becomes a label-and-data string.``
  [item]
  (if (dictionary? item)
    (merge {:label (string (or (item :label) (item :data) ""))} item)
    {:label (string item) :data item}))

(defn- roundtrip
  ``Normalize DATA the way the old pill surface did: through JSON, so tuples
  become arrays and keyword keys survive. Callers hand :data over verbatim but
  receive the same shapes a serialized menu returned.``
  [data]
  (try (json/decode (json/encode data) :keywords true)
       ([_] data)))

(defn- clean [s]
  # fsel splits on the delimiter and on newlines, so neither may reach a cell.
  (->> (string s)
       (string/replace-all "\t" " ")
       (string/replace-all "\n" " ")))

(defn- encode [rows]
  (string/join
    (seq [i :range [0 (length rows)] :let [r (rows i)]]
      (string (clean (r :label)) *delimiter*
              (clean (r :desc)) *delimiter*
              i))
    "\n"))

(defn- fsel-command [&named prompt password]
  (def base "fsel --dmenu --delimiter \"\t\" --match-nth 1,2")
  (if prompt
    (string base " --prompt-only" (if password " --password" ""))
    (string base " --with-nth 1,2 --accept-nth 3 --only-match --exit-if-empty")))

(defn pick
  ``Show ITEMS in the menu surface and return the picked row's :data, or nil if
  the menu was dismissed. ITEMS is a sequence of tables; each may carry a :label,
  :desc and :data (handed back verbatim). TITLE, GLYPH, PROMPT and MESSAGE are
  accepted for compatibility with the old pill surface and ignored: fsel draws
  its own chrome and has nothing to put them in.``
  [items &named title glyph prompt message]
  (def rows (map row (or items @[])))
  (if (empty? rows)
    nil
    (let [in (temp "in")
          out (temp "out")]
      (defer (do (ignore-errors (os/rm in))
                 (ignore-errors (os/rm out)))
        (spit in (encode rows))
        (def code (run (fsel-command) in out))
        (def answer (if (os/stat out :mode) (slurp-stripped out) ""))
        (def index (scan-number answer))
        (if (and (zero? code)
                 index
                 (>= index 0)
                 (< index (length rows)))
          (roundtrip ((rows index) :data))
          nil)))))

(defn read
  ``Prompt for text in the menu surface; return it, or nil if the prompt was
  dismissed. PLACEHOLDER is ignored (fsel has no prompt text), PASSWORD masks
  what is typed, and MULTILINE opens $EDITOR on a temporary file.``
  [&named title placeholder password multiline]
  (if multiline
    (let [file (temp "edit")]
      (defer (ignore-errors (os/rm file))
        (spit file "")
        (def editor (or (os/getenv "VISUAL") (os/getenv "EDITOR") "nvim"))
        (if (zero? (os/execute [editor file] :p))
          (let [text (slurp-stripped file)]
            (if (empty? text) nil text))
          nil)))
    (let [in (temp "in")
          out (temp "out")]
      (defer (do (ignore-errors (os/rm in))
                 (ignore-errors (os/rm out)))
        (spit in "")
        (def code (run (fsel-command :prompt true :password password) in out))
        (if (zero? code)
          (slurp-stripped out)
          nil)))))

(defn prompt
  ``Ask QUESTION with a yes and a no row; return true, false, or nil if the menu
  was dismissed.``
  [question &named yes no]
  (pick [{:label (or yes "Yes") :data true :accent true}
         {:label (or no "No") :data false}]
        :title "CONFIRM" :message question))

(defn launch
  ``Run ARGV in a new session, so whatever a menu starts outlives the terminal
  the menu closes. Use it instead of os/spawn for apps and URL handlers.``
  [& args]
  (os/spawn ["setsid" "-f" ;args] :pd))

(defn notice
  ``Show MESSAGE as a notification. Accepts fmt-style ARGS.``
  [message & args]
  (sys/notify (fmt message ;args)))

(defn error
  ``Show MESSAGE as an error notification, then raise it. Accepts fmt-style
  ARGS.``
  [message & args]
  (sys/toast :error (fmt message ;args) :icon "dialog-error")
  (errorf message ;args))
