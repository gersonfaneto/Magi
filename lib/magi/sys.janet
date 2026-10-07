# lib/magi/sys.janet
#
# An API for the desktop session: sounds, notifications, and the clipboard.

(import spork/json)
(import spork/path)
(use ./lib)
(use sh)

# assets/sounds, as a freedesktop sound theme so the shell plays it too.
(def sound-theme "magi")
# The usual freedesktop list, plus .mp3, which sox handles.
(def sound-exts [".disabled" ".oga" ".ogg" ".wav" ".mp3"])

(defn- sound-dirs []
  [(path/xdg :data "sounds")
   ;(seq [dir :in (string/split ":" (or (os/getenv "XDG_DATA_DIRS")
                                         "/usr/local/share:/usr/share"))
          :unless (empty? dir)]
      (path/join dir "sounds"))])

(defn- sound-themes
  ``THEME and everything it inherits, in lookup order, with freedesktop last
  whether or not anything asked for it.``
  [theme]
  (def dirs (sound-dirs))
  (def themes @[])
  (defn visit [theme]
    (unless (index-of theme themes)
      (when-let [index (find os/stat (map |(path/join $ theme "index.theme") dirs))]
        (array/push themes theme)
        # The spec says comma-separated, then its own example uses spaces.
        (each parent (or (peg/match ~(* (thru "\nInherits=")
                                        (any (+ (<- (some (if-not (set ", \t\r\n") 1)))
                                                (set ", \t"))))
                                    (string "\n" (slurp index)))
                         [])
          (visit parent)))))
  (visit theme)
  (visit "freedesktop")
  themes)

(defn find-sound
  ``The file NAME resolves to in my sound theme: theme by theme, shedding
  NAME's trailing -parts before moving on to the next. nil if nothing does.``
  [name]
  (def dirs (sound-dirs))
  (def parts (string/split "-" (string name)))
  (find os/stat
        (generate [theme :in (sound-themes sound-theme)
                   n :down-to [(length parts) 1]
                   dir :in dirs
                   ext :in sound-exts]
          (path/join dir theme "stereo"
                     (string (string/join (slice parts 0 n) "-") ext)))))

(defn sounds
  "Every name find-sound would resolve, sorted."
  []
  (def dirs (sound-dirs))
  (sorted (distinct (seq [theme :in (sound-themes sound-theme)
                          dir :in dirs
                          :let [stereo (path/join dir theme "stereo")]
                          :when (os/stat stereo)
                          file :in (os/dir stereo)
                          :unless (string/has-suffix? ".disabled" file)]
                      (path/no-ext file ;sound-exts)))))

(defn- detach
  ``Run ARGV in its own session, so a short-lived caller (a menu, say) cannot
  take it down by closing its terminal.``
  [argv]
  (os/spawn ["setsid" "-f" ;argv] :pd))

(defn play-sound
  ``Play NAME from my sound theme; nil if there's no such sound, 0 if the theme
  disables it. Returns play's exit code under WAIT, the detached process
  otherwise.``
  [name &named volume wait]
  (when-let [file (find-sound name)]
    (def argv ["play" "-q" ;(opts "-v" volume) file])
    (cond (string/has-suffix? ".disabled" file) 0
          wait (os/execute argv :p)
          (detach argv))))

(defn notify [message &named urgency title icon sound id]
  # Waited, not detached: a menu exits right after notifying, and the daemon
  # must have taken the message before the caller's terminal goes away.
  (os/execute ["notify-send"
               ;(opts "-i" icon)
               ;(opts "-u" urgency)
               ;(opts "-r" id)
               ;(if title
                  [title message]
                  [message])]
              :p)
  (if sound (play-sound sound)))

(defn toast [type message &named details category icon sound]
  # magi-notifyd owns org.freedesktop.Notifications, so notify-send needs no
  # shell-specific client.
  (def argv @["notify-send" "-a" "magi"
              "-u" (if (= type :error) "critical" "normal")])
  (when category (array/push argv "-c" category))
  (when icon (array/push argv "-i" icon))
  (array/push argv message)
  (when details (array/push argv details))
  (os/execute (array/slice argv) :p)
  (if sound (play-sound sound)))

(defn yank [text &named type once]
  ($? echo ,text | wl-copy ,;(opts "-t" type) ,;(opts (if once "-o"))))

(defn yank-file [file &named type once]
  ($? wl-copy ,;(opts "-t" type) ,;(opts (if once "-o")) ,file))

(defn paste []
  ($<_ wl-paste))
