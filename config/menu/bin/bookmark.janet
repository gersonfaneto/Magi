#!/usr/bin/env janet
# Open a Firefox bookmark.
#
# SYNOPSIS:
#   bookmark [-r|--reload] [--profile PROFILE]
#
# OPTIONS:
#   -r, --reload
#     Reload the cached bookmark list.
#   --profile PROFILE
#     Read bookmarks from PROFILE instead of the default one.

(use magi)
(use sh)
(import magi/menu)
(import magi/vars)
(import sqlite3 :as sql)

(defn- profile-dir [&opt profile]
  (some (fn [dir]
          (when (and (path/directory? dir)
                     (path/file? (path/join dir "profiles.ini")))
            (def file (path/join dir "profiles.ini"))
            (var profile profile)
            (unless profile
              (with [f (file/open file :r)]
                (each l (file/lines f)
                  (when (string/has-prefix? "Path=" l)
                    (set profile (get (string/split "=" l 0 2) 1))
                    (break)))))
            (when profile
              (path/join dir (string/chomp profile)))))
        # The Nix module writes Librewolf's profiles where the browser looks for
        # them by default; the others are where a stock install would put them.
        [(path/xdg :config "librewolf" "librewolf")
         (path/join (os/getenv "HOME") ".librewolf")
         (path/join (os/getenv "HOME") ".mozilla" "librewolf")]))

(defn- db [profile file &opt reload?]
  # Copy the sqlite database to get around locks. Fortunately, FF's dbs are
  # small enough that this is inexpensive. A more ideal alternative would be to
  # open the DB connection in immutable mode, but the janet sqlite3 lib doesn't
  # give us a way to do so.
  (def profile (or (profile-dir profile)
                   (abort "No LibreWolf profile found")))
  (def copy (path :runtime (fmt "browsermenu.%s-%s"
                                (path/basename profile)
                                (path/basename file))))
  (try (do
         (when (or reload? (not (path/file? copy)))
           ($? cp -f ,;(opts (debug?) "-v") ,(path/join profile file) ,copy)
           ($? chmod ,;(opts (debug?) "-v") 400 ,copy))
         (sql/open copy))
       ([err fib]
        (ignore-errors (os/rm copy))
        (propagate err fib))))

(def- *vars*  (vars/new (:dir (vars/global) :menu :bookmark)))
(def- *icons* (vars/new (:dir *vars* :icons) true))

(defn- icon-file [data]
  (when data
    (let [key (string (hash data))]
      (:cache *icons* key |data)
      (:file *icons* key))))

(defn bookmarks [profile &opt reload?]
  # Keyed by profile: the cache outlives the process, and `--profile alt` must
  # not hand back the default profile's list.
  (:cache *vars* (string "bookmarks-" (or profile "default"))
    |(with [dbbk (db profile "places.sqlite" reload?)]
       (let [res (sql/eval dbbk `
                   SELECT mb.id, mb.parent, mb.type, mb.title, mp.url FROM moz_bookmarks mb
                   LEFT JOIN moz_places mp ON mb.fk = mp.id
                   WHERE mb.type = 1 AND mb.title<>''
                   ORDER BY mp.frecency DESC
                 `)]
         (with [dbfav (db profile "favicons.sqlite" reload?)]
           (eachp [i v] res
             (def {:title title :url url} v)
             (when url
               (def favs (sql/eval dbfav (fmt `
                           SELECT max(ic.data) AS data FROM moz_pages_w_icons pg, moz_icons_to_pages rel, moz_icons ic
                           WHERE pg.id = rel.page_id AND ic.id=rel.icon_id AND (pg.page_url="%s" OR pg.page_url LIKE '%%%s%%')
                           LIMIT 1
                         ` url (first (string/split "/" (peg/replace '(* "http" (? "s") "://" (? "www.")) "" url) 0 2)))))
               (unless (empty? favs)
                 (put res i (struct ;(kvs v) :favicon (icon-file (get (first favs) :data))))))))
         res))
    reload?))

(defn- open-url [url]
  (when url
    (echof "Opening: %s" url)
    (os/spawn ["xdg-open" url] :pd)))

(defn- select [profile reload?]
  (def items @[{:label "Reload bookmarks ->" :icon "reload" :data "@reload"}])
  (each e (bookmarks profile reload?)
    (when-let [url (e :url)]
      (array/push items
                  {:label (if (empty? (e :title)) url (e :title))
                   :desc url
                   :icon (or (e :favicon) "link")
                   :data url})))
  (menu/pick items :title "BOOKMARKS" :prompt "Search bookmarks"))

(defmain [_ &opts
          profile [--profile name]
          reload? [-r --reload]]
  (if-not (profile-dir profile)
    (menu/notice "No LibreWolf profile found")
    (do
      (var reload? reload?)
      (var running true)
      (while running
        (def sel (select profile reload?))
        (cond
          (nil? sel) (set running false)
          (= sel "@reload") (set reload? true)
          (do (open-url sel) (set running false)))))))
