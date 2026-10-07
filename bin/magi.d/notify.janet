#!/usr/bin/env janet
# Read or clear the notification log magi-notifyd keeps.
#
# SYNOPSIS:
#   notify [list] [-n N] [--json]
#   notify clear
#
# OPTIONS:
#   -n, --limit N
#     Show at most the last N notifications (default 20).
#   --json
#     Print the raw JSON lines instead of a formatted list.
#
# ARGUMENTS:
#   1 COMMAND
#     list  -- Print recent notifications (the default).
#     clear -- Empty the log.

(use magi)
(import spork/json :as json)

(defn- log-file []
  (path :state "notifications.jsonl"))

(defn- entries []
  (def file (log-file))
  (if (path/file? file)
    (map |(json/decode $ :keywords true)
         (filter |(not (empty? $)) (string/split "\n" (slurp file))))
    @[]))

(defn- line [entry]
  (def d (os/date (or (entry :time) 0) false))
  (def app (or (entry :app) ""))
  (def summary (or (entry :summary) ""))
  (def body (or (entry :body) ""))
  (string/format "%02d:%02d %s%s%s"
                 (d :hours) (d :minutes)
                 (if (empty? app) "" (string app ": "))
                 summary
                 (if (empty? body) "" (string " -- " body))))

(defn- show [limit json?]
  (def notifications (entries))
  (for i (max 0 (- (length notifications) limit)) (length notifications)
    (def entry (notifications i))
    (if json?
      (print (json/encode entry))
      (print (line entry)))))

(defn- clear []
  (def file (log-file))
  (when (path/file? file)
    (spit file ""))
  (print "notifications cleared"))

(defcmd notify [_ cmd & args &opts json? --json limit [-n --limit limit]]
  (case cmd
    nil (show (or (and limit (scan-number limit)) 20) json?)
    "list" (show (or (and limit (scan-number limit)) 20) json?)
    "clear" (clear)
    (usage)))
