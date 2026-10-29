#!/usr/bin/env janet
# Pick a Bitwarden entry with rbw and copy one of its fields to the clipboard.
#
# SYNOPSIS:
#   rbw [--field FIELD] [--new]
#
# OPTIONS:
#   --field FIELD
#     Copy FIELD without opening the field picker. Use a name reported by
#     `rbw get --list-fields`, such as password, username, uris, totp or notes.
#   --new
#     Open the new-entry flow instead of the entry list.

(use magi)
(use sh)
(import magi/menu)
(import magi/sys)

(def- *field-info*
  {"password" {:label "Password" :glyph "lock" :desc "Copy the login password"}
   "username" {:label "Username" :glyph "type" :desc "Copy the account name"}
   "uris"     {:label "URL" :glyph "language" :desc "Copy the website address"}
   "totp"     {:label "TOTP" :glyph "clock" :desc "Copy the current one-time code"}
   "notes"    {:label "Notes" :glyph "inbox" :desc "Copy the entry's notes"}})

# rbw lists fields alphabetically; put the ones I reach for first, and keep any
# custom field after them.
(def- *field-order* ["password" "username" "totp" "uris" "notes"])

(var *editor-seq* 0)

# Favicons are cached by host. A background worker fills the cache; until it
# does, rows fall back to the baked glyph for their entry type.
(def- *warm-script*
  (string/join
    ["dir=$1; shift"
     "lock=\"$dir/.lock\""
     "mkdir \"$lock\" 2>/dev/null || exit 0"
     "trap 'rmdir \"$lock\"' EXIT"
     "for host in \"$@\"; do"
     "  out=\"$dir/$host.png\""
     "  [ -s \"$out\" ] && continue"
     "  tmp=\"$out.tmp.$$\""
     "  if curl -fsSL --connect-timeout 2 --max-time 5 --max-filesize 262144 \\"
     "       \"https://$host/favicon.ico\" -o \"$tmp\"; then"
     "    case \"$(od -An -tx1 -N4 \"$tmp\" | tr -d '[:space:]')\" in"
     "      89504e47|00000100|47494638|ffd8ff|52494646) mv \"$tmp\" \"$out\"; continue ;;"
     "    esac"
     "    rm -f \"$tmp\""
     "  fi"
     "  if curl -fsSL --connect-timeout 2 --max-time 5 --max-filesize 262144 \\"
     "       \"https://www.google.com/s2/favicons?domain=$host&sz=64\" -o \"$tmp\"; then"
     "    mv \"$tmp\" \"$out\""
     "  else"
     "    rm -f \"$tmp\""
     "  fi"
     "done"]
    "\n"))

(def- *sync-script*
  (string/join
    ["log=$1"
     "if rbw sync >\"$log\" 2>&1; then"
     "  exit 0"
     "fi"
     "detail=$(tail -n 3 \"$log\" | tr '\\n' ' ')"
     "notify-send -a magi -u critical -i dialog-error \\"
     "  \"Bitwarden sync failed\" \"$detail\""
     "exit 1"]
    "\n"))

(defn- field-label [field]
  (get-in *field-info* [field :label] field))

(defn- field-item [field]
  (def info (or (get *field-info* field) {}))
  (merge {:label field :glyph "cursor" :desc "Copy this custom field" :data field}
         info))

(defn- entry-desc [entry]
  (string/join
    (filter |(not (empty? $))
            [(or (entry :user) "")
             (if-let [folder (entry :folder)] (string "in " folder) "")
             (or (first (entry :uris)) "")])
    "  "))

(defn- entry-glyph [entry]
  (case (entry :type)
    "Login"    "lock"
    "Note"     "inbox"
    "Card"     "layers"
    "Identity" "type"
    "lock"))

(defn- magi-cache-dir []
  (def cache (or (os/getenv "XDG_CACHE_HOME")
                 (path/join (os/getenv "HOME") ".cache")))
  (path/join cache "magi"))

(defn- icon-dir []
  (path/join (magi-cache-dir) "rbw-icons"))

(defn- uri-host [uri]
  (when-let [start (string/find "://" uri)]
    (var host (string/slice uri (+ start 3)))
    (each sep ["/" "?" "#"]
      (when-let [end (string/find sep host)]
        (set host (string/slice host 0 end))))
    (when-let [at (string/find "@" host)]
      (set host (string/slice host (inc at))))
    (when-let [colon (string/find ":" host)]
      (set host (string/slice host 0 colon)))
    (unless (empty? host) host)))

(defn- entry-host [entry]
  (some uri-host (or (entry :uris) [])))

(defn- cached-icon [host]
  (when host
    (def file (path/join (icon-dir) (string host ".png")))
    (when (and (path/file? file)
               (pos? (or (os/stat file :size) 0)))
      file)))

(defn- warm-icons [hosts]
  (when (not (empty? hosts))
    (def batch (slice hosts 0 (min (length hosts) 12)))
    (def dir (icon-dir))
    (ignore-errors (os/execute ["mkdir" "-p" dir] :p))
    (os/spawn ["sh" "-c" *warm-script* "_" dir ;batch] :pd)))

(defn- sync-background []
  (def dir (magi-cache-dir))
  (ignore-errors (os/execute ["mkdir" "-p" dir] :p))
  (os/spawn ["sh" "-c" *sync-script* "_" (path/join dir "rbw-sync.log")] :pd))

(defn- vault-unlocked? []
  (do? $? rbw unlocked))

(defn- list-entries []
  (unless (path/find "rbw")
    (menu/error "rbw is not installed"))
  (if (vault-unlocked?)
    (do
      (def raw (string/trimr ($<_ rbw list --raw)))
      (def entries (if (empty? raw) nil (ignore-errors (json/decode raw :keywords true))))
      (unless (array? entries)
        (menu/error "Could not list Bitwarden entries; is rbw configured?"))
      entries)
    nil))

(defn- pick-entry [entries]
  (def hosts (distinct (filter identity (map entry-host entries))))
  (warm-icons (filter |(not (cached-icon $)) hosts))
  (def items @[])
  (each entry entries
    (def host (entry-host entry))
    (def icon (cached-icon host))
    (array/push items
                (merge {:label (entry :name)
                        :desc (entry-desc entry)
                        :glyph (entry-glyph entry)
                        :data {:id (entry :id)
                               :name (entry :name)
                               :uris (entry :uris)}}
                       (if icon {:icon icon} {}))))
  (array/push items
              {:label "New entry"
               :desc "Save a new Bitwarden login"
               :glyph "sparkles"
               :data {:action "new"}}
              {:label "Sync vault"
               :desc "Update the local Bitwarden copy"
               :glyph "download"
               :data {:action "sync"}})
  (menu/pick items
             :title "BITWARDEN" :glyph "鍵" :prompt "Search Bitwarden entries"))

(defn- pick-locked []
  (menu/pick
    [{:label "Unlock vault"
      :desc "Unlock the local Bitwarden database"
      :glyph "lock-outline"
      :data {:action "unlock"}
      :accent true}]
    :title "BITWARDEN" :glyph "鍵" :message "The vault is locked"))

(defn- unlock-vault []
  (if (do? $? rbw unlock)
    (do
      (sys/notify "Bitwarden vault unlocked"
                  :title "Bitwarden" :icon "dialog-password" :sound "blip")
      true)
    (do
      (menu/notice "Could not unlock the Bitwarden vault")
      false)))

(defn- normalize-uri [uri]
  (when uri
    (def text (string/trim uri))
    (unless (empty? text)
      (if (string/find "://" text)
        text
        (string "https://" text)))))

(defn- yank-secret [text]
  ($? echo ,text | wl-copy --sensitive))

(defn- prompt-new [placeholder &named password]
  (menu/read :title "NEW ENTRY" :placeholder placeholder :password password))

(defn- prompt-notes [placeholder]
  (menu/read :title "ENTRY NOTES" :placeholder placeholder :multiline true))

(defn- password-choice []
  (menu/pick
    [{:label "Generate password"
      :desc "20 random characters"
      :glyph "sparkles"
      :data {:kind "generate" :len 20}}
     {:label "Generate long password"
      :desc "32 random characters"
      :glyph "sparkles"
      :data {:kind "generate" :len 32}}
     {:label "Generate passphrase"
      :desc "6 words from the EFF word list"
      :glyph "type"
      :data {:kind "generate" :len 6 :diceware true}}
     {:label "Type a password"
      :desc "Enter an existing password"
      :glyph "lock"
      :data {:kind "custom"}}]
    :title "PASSWORD" :glyph "鍵" :prompt "Choose how to make the password"))

(defn- generate-password [choice]
  (def args @["rbw" "generate" (string (choice :len))])
  (when (choice :diceware)
    (array/push args "--diceware"))
  (def out @"")
  (unless (do? $? ,;args > ,out)
    (menu/error "Could not generate a password"))
  (string/trimr out))

(defn- with-entry-editor [password notes f]
  (def suffix (string/format "%d-%d" (os/getpid) (++ *editor-seq*)))
  (def editor (path :runtime (string "rbw-editor-" suffix)))
  (def content (path :runtime (string "rbw-entry-" suffix)))
  (def note-text
    (if (empty? notes)
      ""
      (string notes (if (string/has-suffix? "\n" notes) "" "\n"))))
  (spit content (string password "\n" note-text))
  (os/chmod content 8r600)
  (spit editor "#!/bin/sh\ncat \"$RBW_ENTRY_FILE\" > \"$1\"\n")
  (os/chmod editor 8r700)
  (defer (do
           (ignore-errors (os/rm editor))
           (ignore-errors (os/rm content)))
    (with-envvars ["EDITOR" editor
                   "VISUAL" editor
                   "RBW_ENTRY_FILE" content]
      (f))))

(defn- add-entry [name user uri password notes]
  (with-entry-editor password notes
    (fn []
      (def args @["rbw" "add" name])
      (unless (empty? user)
        (array/push args user))
      (when uri
        (array/push args "--uri" uri))
      (unless (do? $? ,;args)
        (menu/error "Could not add %s" name)))))

(defn- finish-new [name uri password]
  (if (empty? password)
    (sys/notify (fmt "Created %s" name)
                :title "Bitwarden" :icon "dialog-password" :sound "blip")
    (do
      (yank-secret password)
      (sys/notify (fmt "Created %s and copied its password" name)
                  :title "Bitwarden" :icon "dialog-password" :sound "blip")))
  (when-let [host (and uri (uri-host uri))]
    (warm-icons [host]))
  (sync-background))

(defn- new-entry []
  (def name (prompt-new "Name"))
  (when (and name (not (empty? (string/trim name))))
    (def user (prompt-new "Username (optional)"))
    (when user
      (def uri-input (prompt-new "Website URL (optional)"))
      (when uri-input
        (def choice (password-choice))
        (when choice
          (def password
            (if (= (choice :kind) "custom")
              (prompt-new "Password" :password true)
              nil))
          (when (or (not= (choice :kind) "custom") password)
            (def notes (prompt-notes "Notes (optional)"))
            (when notes
              (def name (string/trim name))
              (def user (string/trim user))
              (def uri (normalize-uri uri-input))
              (def password
                (if (= (choice :kind) "custom")
                  password
                  (generate-password choice)))
              (add-entry name user uri password notes)
              (finish-new name uri password))))))))

(defn- sync-vault []
  (if (do? $? rbw sync)
    (sys/notify "Bitwarden vault synced"
                :title "Bitwarden" :icon "dialog-password" :sound "blip")
    (menu/error "Could not sync Bitwarden vault")))

(defn- list-fields [entry]
  (def out @"")
  (unless (do? $? rbw get --list-fields ,(entry :id) > ,out)
    (menu/error "Could not list fields for %s" (entry :name)))
  (def fields (filter |(not (empty? $)) (string/split "\n" (string/trimr out))))
  (def ordered @[])
  (each field *field-order*
    (when (index-of field fields)
      (array/push ordered field)))
  (each field fields
    (unless (index-of field *field-order*)
      (array/push ordered field)))
  ordered)

(defn- pick-field [entry]
  (def items (map field-item (list-fields entry)))
  (when-let [uri (first (or (entry :uris) []))]
    (array/push items
                {:label "Open website"
                 :glyph "language"
                 :desc uri
                 :data ["open-url" uri]}))
  (array/push items
              {:label "Edit password"
               :glyph "pencil"
               :desc "Set a new login password"
               :data ["edit-password"]}
              {:label "Edit notes"
               :glyph "inbox"
               :desc "Replace the entry notes"
               :data ["edit-notes"]}
              {:label "Delete entry"
               :glyph "trash"
               :desc "Remove this entry from Bitwarden"
               :data ["delete"]})
  (menu/pick items
             :title (entry :name) :glyph "鍵" :prompt "Search fields and actions"))

(defn- read-field [entry field]
  (def out @"")
  (unless (do? $? rbw get --field ,field ,(entry :id) > ,out)
    (menu/error "Could not read %s for %s" field (entry :name)))
  (string/trimr out))

(defn- maybe-field [entry field]
  (if (index-of field (list-fields entry))
    (read-field entry field)
    ""))

(defn- secret-field? [field]
  (or (= field "password") (= field "totp")))

(defn- copy-field [entry field]
  (def value (read-field entry field))
  (if (empty? value)
    (menu/notice "%s is empty for %s" (field-label field) (entry :name))
    (do
      (if (secret-field? field)
        (yank-secret value)
        (sys/yank value))
      (sys/notify (fmt "Copied %s for %s" (field-label field) (entry :name))
                  :title "Bitwarden" :icon "dialog-password" :sound "blip"))))

(defn- edit-entry [entry password notes]
  (with-entry-editor password notes
    (fn []
      (unless (do? $? rbw edit ,(entry :id))
        (menu/error "Could not edit %s" (entry :name))))))

(defn- edit-password [entry]
  (when-let [choice (password-choice)]
    (def password
      (if (= (choice :kind) "custom")
        (prompt-new "New password" :password true)
        (generate-password choice)))
    (when (or (not= (choice :kind) "custom") password)
      (edit-entry entry password (maybe-field entry "notes"))
      (if (empty? password)
        (sys/notify (fmt "Updated password for %s" (entry :name))
                    :title "Bitwarden" :icon "dialog-password" :sound "blip")
        (do
          (yank-secret password)
          (sys/notify (fmt "Updated %s and copied its password" (entry :name))
                      :title "Bitwarden" :icon "dialog-password" :sound "blip")))
      (sync-background))))

(defn- edit-notes [entry]
  (when-let [notes (prompt-notes "Notes (blank clears)")]
    (edit-entry entry (maybe-field entry "password") notes)
    (sys/notify (fmt "Updated notes for %s" (entry :name))
                :title "Bitwarden" :icon "dialog-password" :sound "blip")
    (sync-background)))

(defn- delete-entry [entry]
  (when (menu/prompt (fmt "Delete %s?" (entry :name)) :yes "Delete" :no "Cancel")
    (unless (do? $? rbw remove ,(entry :id))
      (menu/error "Could not delete %s" (entry :name)))
    (sys/notify (fmt "Deleted %s" (entry :name))
                :title "Bitwarden" :icon "dialog-password" :sound "blip")
    (sync-background)))

(defn- handle-field [entry selection]
  (if (array? selection)
    (case (selection 0)
      "open-url" (os/spawn ["xdg-open" (selection 1)] :pd)
      "edit-password" (edit-password entry)
      "edit-notes" (edit-notes entry)
      "delete" (delete-entry entry)
      nil)
    (copy-field entry selection)))

(defn- browse [entries fixed-field]
  (var current entries)
  (var running true)
  (while running
    (when (nil? current)
      (def locked (pick-locked))
      (if (nil? locked)
        (set running false)
        (when (unlock-vault)
          (set current (list-entries)))))
    (when current
      (def sel (pick-entry current))
      (if (nil? sel)
        (set running false)
        (case (sel :action)
          "new" (do (new-entry)
                    (set current (list-entries)))
          "sync" (do (sync-vault)
                     (set current (list-entries)))
          (do
            (def field (or fixed-field (pick-field sel)))
            (when field
              (handle-field sel field))
            (set running false)))))))

(defmain [_ &opts field [--field f] new? [--new]]
  (if new?
    (new-entry)
    (browse (list-entries) field)))
