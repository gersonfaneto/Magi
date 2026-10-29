-- config/hypr/modules/windowmenu.lua
--
-- SUPER+SHIFT+W window picker. The list is drawn by the Quickshell pill's
-- generic menu surface (config/quickshell/pill/Menu.qml), not rofi: we build the
-- rows from the Hyprland lua API, write them to a runtime file (read back over
-- menuFile so a long window list never rides on an argv), and picking a row
-- focuses its window through the surface's callback. Escaping the surface leaves
-- focus where it was.

local function shquote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- Minimal JSON string escaping; window titles routinely carry quotes and
-- backslashes, and a raw one would break the payload the shell hands to qs.
local function jesc(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
  return (s:gsub("%c", ""))
end

local function payload()
  local rows = {}
  for _, w in ipairs(hl.get_windows() or {}) do
    local title = w.title
    if not title or title == "" then
      title = "Untitled"
    end
    local class = w.class or ""
    local ws = w.workspace and w.workspace.name or ""
    local desc = class
    if ws ~= "" then
      desc = (class ~= "" and (class .. "  ·  ws " .. ws)) or ("ws " .. ws)
    end
    rows[#rows + 1] = string.format(
      '{"label":"%s","desc":"%s","icon":"%s","data":"%s"}',
      jesc(title), jesc(desc), jesc(class), jesc(w.address or ""))
  end
  return string.format(
    '{"title":"WINDOWS","glyph":"窓","prompt":"Search windows",'
    .. '"items":[%s],'
    .. '"callback":["hyprctl","dispatch","hl.dsp.focus({ window = \'address:{}\' })"]}',
    table.concat(rows, ","))
end

local function open()
  local path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-windowmenu.json"
  local f = io.open(path, "w")
  if not f then
    return
  end
  f:write(payload())
  f:close()
  hl.exec_cmd("qs -c pill ipc call pill menuFile " .. shquote(path))
end

hl.bind("SUPER + SHIFT + w", open)
hl.bind("SUPER + SHIFT + TAB", open)
