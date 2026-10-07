#!/usr/bin/env janet
# Pick an emoji and copy it.
#
# SYNOPSIS:
#   emoji

(use magi)
(import magi/menu)
(import magi/sys)

# Vendored from rofimoji; see the README beside them.
(def- *emoji-dir* (path :config "menu" "data" "emoji"))

(defn- files []
  (sorted (filter |(string/has-suffix? ".csv" $)
                  (or (ignore-errors (os/dir *emoji-dir*)) []))))

(defn- group [file]
  (string/replace-all "_" " " (string/no-prefix "emojis_" (path/no-ext file))))

(defn- parse
  ``Split "CHAR NAME <small>(keywords)</small>" into [CHAR NAME].``
  [line]
  (when-let [sp (string/find " " line)]
    (def char (string/slice line 0 sp))
    (var name (string/slice line (inc sp)))
    (when-let [cut (string/find " <small>" name)]
      (set name (string/slice name 0 cut)))
    [char name]))

(defn- catalogue []
  (def out @[])
  (each file (files)
    (def cat (group file))
    (each line (string/split "\n" (slurp (path/join *emoji-dir* file)))
      (unless (empty? line)
        (when-let [[char name] (parse line)]
          (array/push out {:label (string char "  " name)
                           :desc cat
                           :data char})))))
  out)

(defmain [_]
  (when-let [sel (menu/pick (catalogue) :title "EMOJI" :glyph "顔" :prompt "Search emoji")]
    (sys/yank sel)
    (sys/notify sel :title "Copied emoji")))
