#!/usr/bin/env janet
# Open a file, or a terminal in a directory.
#
# SYNOPSIS:
#   file [--dir DIR] [--dirs] [--depth N]
#
# OPTIONS:
#   --dir DIR
#     Start in DIR (default $HOME).
#   --dirs
#     List directories only (down to --depth) and open a terminal in the one
#     picked, instead of browsing.
#   --depth N
#     How deep --dirs descends (default 3).

(use magi)
(import magi/menu)

(defn- visible? [name]
  (not (string/has-prefix? "." name)))

(defn- listing [dir]
  (def dirs @[])
  (def files @[])
  (each name (sorted (or (ignore-errors (os/dir dir)) []))
    (when (visible? name)
      (def full (path/join dir name))
      (if (path/directory? full)
        (array/push dirs full)
        (array/push files full))))
  [dirs files])

(defn- open-term [dir]
  (os/spawn ["magi" ".open-term" "-t" (path/basename dir) "--" "-c" dir] :pd))

(defn- open-file [file]
  (os/spawn ["xdg-open" file] :pd))

(defn- browse [start]
  (var dir (path/abspath start))
  (var running true)
  (while running
    (def [dirs files] (listing dir))
    (def items @[{:label "Open in terminal ->" :icon "utilities-terminal"
                  :data ["term" dir]}])
    (unless (= dir "/")
      (array/push items {:label ".." :icon "go-up" :data ["open" (path/dirname dir)]}))
    (each d dirs
      (array/push items {:label (string (path/basename d) "/") :icon "folder"
                         :data ["open" d]}))
    (each f files
      (array/push items {:label (path/basename f) :icon "text-x-generic"
                         :data ["file" f]}))
    (def sel (menu/pick items :title (path/abbrev dir) :glyph "文" :prompt "Search"))
    (if (nil? sel)
      (set running false)
      (case (sel 0)
        "open" (set dir (sel 1))
        "term" (do (open-term (sel 1)) (set running false))
        "file" (do (open-file (sel 1)) (set running false))
        (set running false)))))

(defn- walk
  ``Every directory under ROOT, DEPTH levels deep, in a flattened, sorted list.``
  [root depth]
  (def out @[])
  (defn visit [dir d]
    (each name (sorted (or (ignore-errors (os/dir dir)) []))
      (when (visible? name)
        (def full (path/join dir name))
        (when (path/directory? full)
          (array/push out full)
          (when (< d depth)
            (visit full (inc d)))))))
  (visit root 1)
  out)

(defn- choose-dir [root depth]
  (def items
    (map (fn [d] {:label (path/abbrev d) :icon "folder" :data d})
         (walk root depth)))
  (when-let [sel (menu/pick items :title "DIRECTORIES" :glyph "文" :prompt "Search directories")]
    (open-term sel)))

(defmain [_ &opts
          start [--dir path]
          dirs? [--dirs]
          depth [--depth n]]
  (def root (or start (os/getenv "HOME") "/"))
  (if dirs?
    (choose-dir root (scan-number (or depth "3")))
    (browse root)))
