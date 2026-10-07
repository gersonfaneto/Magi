#!/usr/bin/env janet
# Preview and copy an icon name.
#
# SYNOPSIS:
#   icon [-l|--list] [-r|--reload]
#
# DESCRIPTION:
#   Preview and select an icon (either from installed icon themes or from
#   tabler-icons; the bundled icon set). Copies the selected icon's name to
#   clipboard.
#
# OPTIONS:
#   -l, --list
#     Print what the menu would show and don't open it.
#   -r, --reload
#     Rescan the themes rather than trust the cache.

(use magi)
(use sh)
(import magi/menu)
(import magi/sys)
(import magi/vars)
(import spork/json :as json)
(import spork/sh :as fs)

# tabler.json ships in the checkout; the svgs are fetched by modules/apps/menu.nix.
(def- *data-dir* (path :config "menu" "data"))
(def- *tabler-dir* (path :data "tabler-icons"))

(defn- icon-roots []
  # Where the icon theme spec says to look, minus the ones I don't have.
  (filter path/directory?
          (distinct
           [(path/join (os/getenv "HOME") ".icons")
            (path/xdg :data "icons")
            ;(map |(path/join $0 "icons")
                  (string/split ":" (or (os/getenv "XDG_DATA_DIRS") "")))])))

(defn- theme-dirs []
  # Every theme here is a symlink into the store, and find won't descend one
  # unless I hand it the resolved path. Sorted because os/dir hands me readdir
  # order, and I'd rather ties below (and the cache key) not hinge on that.
  (distinct
   (seq [root :in (icon-roots)
         name :in (sorted (or (ignore-errors (os/dir root)) []))
         :let [dir (path/join root name)]
         :when (path/directory? dir)]
     (os/realpath dir))))

(def- *size-peg* (peg! ~(some (+ (* (<- :d+) "x" :d+) 1))))

(defn- resolution
  ``How big FILE's copy of an icon is, for picking between the dozen sizes every
  theme ships. A 16px preview is a smudge, so scalable wins outright.``
  [file]
  (if (string/find "/scalable/" file)
    math/inf
    (scan-number (or (first (peg/match *size-peg* file)) "0"))))

(defn- scan-icons
  ``{ NAME {:file PATH :theme THEME :link TARGET} } for every icon in DIRS. One
  find beats walking 90k files from janet.``
  [dirs]
  (def out ($<_ find ,;dirs
                "(" -name "*.svg" -o -name "*.png" -o -name "*.xpm" ")"
                # %H is the theme dir I handed find; %l is the symlink's target,
                # and empty for a real file.
                -printf "%H\t%p\t%l\n"))
  (def best @{})
  (loop [line :in (string/split "\n" out)
         :unless (empty? line)
         :let [[root file link] (string/split "\t" line)
               name (path/no-ext (path/basename file))
               size (resolution file)]
         # Biggest copy wins; ties go to the first theme dir, so anything I
         # dropped in ~/.icons myself outranks the system's.
         :when (> size (get-in best [name :size] -1))]
    (put best name {:file file
                    :link link
                    :size size
                    :theme (path/basename root)}))
  best)

# Lives in $XDG_RUNTIME_DIR, so a reboot rescans whether I ask it to or not.
(def- *vars* (vars/new (:dir (vars/temp) :menu :icon)))

(defn- icons [&opt reload?]
  # The theme's store path makes for a good cache key
  (def dirs (theme-dirs))
  (def key (string (hash (string/join dirs ":"))))
  (or (unless reload? (:get *vars* key))
      (let [found (scan-icons dirs)]
        # A miss means the old key's entry is 3MB of dead weight. Sweep first.
        (:clear *vars*)
        (:set *vars* key found)
        found)))

(defn- palette-fg
  ``The colour the desktop is drawing text in, read from the bundle theme.py
  keeps current. It is the only live palette that exists as a hex librsvg can
  take.``
  []
  (def file (path :state "theme" "palettes" "current.json"))
  (def bundle
    (when (path/file? file)
      (ignore-errors (json/decode (slurp file) :keywords true))))
  (when (dictionary? bundle)
    (def hex (or (bundle :cream) (bundle :on_surface) (bundle :bright)))
    (when (and (string? hex) (not (empty? hex)))
      (if (string/has-prefix? "#" hex) hex (string "#" hex)))))

# Upstream draws every icon in `currentColor`, which librsvg (and rofi by
# extension) renders to black, which is horrible on dark palettes. So copy and
# fix them before presenting them!
(defn- recoloured
  ``*tabler-dir* in COLOR, cached under it.``
  [color]
  (def dir (:dir *vars* (string "svg-" (string/slice color 1))))
  (unless (path/directory? dir)
    (def tmp (string dir ".new"))
    (fs/create-dirs (path/dirname tmp))
    # The palette may change, piling up in tmpfs ~2M at a time
    (each old (path/files-in (:dir *vars*))
      (when (string/has-prefix? "svg-" (path/basename old))
        (fs/rm old)))
    # -L because home-manager hands me a symlink into the store, and without it
    # cp copies the link, find declines to follow it, and sed silently edits
    # nothing at all. --no-preserve=mode because the store is 444.
    ($ cp -rLT --no-preserve=mode ,*tabler-dir* ,tmp)
    ($ find ,tmp -name "*.svg"
       -exec sed -i ,(string "s/currentColor/" color "/g") "{}" "+")
    (os/rename tmp dir))
  dir)

(defn- tabler-json
  ``The name/codepoint table for the tabler icon font, vendored in the checkout.``
  []
  (let [file (path/join *data-dir* "tabler.json")]
    (when (path/file? file) file)))

(defn- tabler-icons
  ``{ NAME {:theme CATEGORY :codepoint "U+EC36" :file PATH} } for every glyph in
  the tabler icon font. The SVGs come from the `magi/tabler-icons` data dir; the
  name table rides along with the checkout. No cache: it's one 500K json against
  the themes' 90k files.``
  [&opt _reload?]
  (def file (tabler-json))
  (if-not file
    {}
    (let [svgs (when (path/directory? *tabler-dir*) (recoloured (or (palette-fg) "#f2f2f2")))
          have (if svgs
                 (tabseq [f :in (os/dir svgs)] (path/no-ext f ".svg") true)
                 {})]
      (tabseq [[name entry] :pairs (json/decode (slurp file))]
        name {:theme (get entry "category")
              :codepoint (get entry "codepoint")
              :file (when (have name) (path/join svgs (string name ".svg")))}))))

(def- *icon* [["xdg" icons] ["tabler" tabler-icons]])

(defn- catalogue
  ``Every icon from every set, flattened and tagged with where it came from.
  Sorted by name rather than grouped, so the two spellings of `battery` land
  next to each other instead of six thousand rows apart.``
  [&opt reload?]
  (def out @[])
  (each [set list-icons] *icon*
    (eachp [name entry] (list-icons reload?)
      (array/push out (merge entry {:name name :set set
                                    :sort (string name " " set)}))))
  (sorted-by |($0 :sort) out))

(defn- linked-to [entry]
  (let [link (get entry :link "")]
    (unless (empty? link)
      (path/no-ext (path/basename link)))))

(defn- row [entry]
  (def target (linked-to entry))
  {:label (entry :name)
   :desc (string/join (filter |(not (empty? $))
                              [(entry :set)
                               (or (entry :theme) "")
                               (or (entry :codepoint) "")
                               (if target (string "-> " target) "")])
                      "  ")
   :icon (or (entry :file) (entry :name))
   # Glyphs without an svg go without; the name still selects.
   :data [(entry :name) (or (entry :file) (entry :name))]})

(defn- select-icon [&opt reload?]
  (def items @[{:label "Reload icons ->" :icon "reload" :data "@reload"}])
  (each entry (catalogue reload?)
    (array/push items (row entry)))
  (menu/pick items :title "ICONS" :glyph "絵" :prompt "Search icons"))

(defmain [_ &opts
          list?   [-l --list]
          reload? [-r --reload]]
  (if list?
    (each entry (catalogue reload?)
      (echof "%s\t%s\t%s\t%s%s" (entry :set) (entry :name) (entry :theme)
             (or (entry :file) (entry :codepoint))
             (if-let [target (linked-to entry)] (string "\t-> " target) "")))
    (do
      (var reload? reload?)
      (var running true)
      (while running
        (def sel (select-icon reload?))
        (cond
          (nil? sel) (set running false)
          (= sel "@reload") (set reload? true)
          (do
            # For a glyph that's its own name, which is what the shell wants anyway.
            (def [name icon] sel)
            (sys/yank name)
            (sys/notify name :title "Copied icon name" :icon icon)
            (set running false)))))))
