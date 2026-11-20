-- Convenience mappings for Neovim's builtin multicursor (|multicursor|).
-- See `:h mcursor` and `:h mcursor-examples`.
--
-- Everything lives under the `<M-m>` prefix so it cannot shadow the
-- window/tmux navigation on `<M-hjkl>` or the insert helpers on `<M-i>` and
-- `<M-a>` (see `lua/minimal/core/keymaps.lua` and
-- `lua/minimal/plugin/tmux.lua`).
--
-- Builtins worth knowing:
--   `Q`        toggle a cursor at the cursor position
--   `q=`       toggle follow mode
--   `[C`, `]C` jump to the previous/next cursor
--   `<C-L>`    clear all cursors in the buffer
--
-- Mappings:
--   `<M-m>j`, `<M-m>k` add a cursor and move down/up
--   `<M-m>a`           add a cursor at every occurrence of the word or
--                      Visual selection (whole buffer)
--   `<M-m>n`, `<M-m>N` add a cursor and move to the next/previous
--                      occurrence
--   `<M-m>r`           rebuild the search pattern from the word or
--                      Visual selection
--   `<M-m>c`           clear all cursors
--   `<M-m>f`           toggle follow mode
--   `<M-m>d`           remove the cursor under the cursor
--   `<M-m>x`           go back to the previous cursor and remove it
--
-- Inspired by https://redd.it/1w63ltg

---@class minimal.plugin.multicursor
local M = {}

local ns = vim.api.nvim_create_namespace('nvim.multicursor')

---Search pattern per buffer, so `n`/`N` keep using the pattern that started
---the multicursor session instead of whatever is in the search register.
---@type table<integer, string>
local patterns = {}

---Add a cursor at a buffer position
---@param row integer 0-based row
---@param col integer 0-based column
---@return nil
local function add_cursor(row, col)
  vim.api.nvim_buf_set_extmark(0, ns, row, col, {})
end

---Check whether a multicursor session is active in the current buffer
---@return boolean
local function has_cursors()
  return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1) > 0
end

---Clear all cursors in the current buffer
---@return nil
local function clear_cursors()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

---Check whether Visual mode is currently active
---@return boolean
local function in_visual_mode()
  return vim.fn.mode():find('^[vV\22]') ~= nil
end

---Leave Visual mode synchronously
---@return nil
local function escape_visual()
  if in_visual_mode() then
    vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
  end
end

---Escape text for a very nomagic (`\V`) search pattern
---@param text string
---@return string
local function escape_pattern(text)
  return (text:gsub('\\', '\\\\'))
end

---Build a pattern for the current Visual selection
---@return string?
local function selection_pattern()
  local selection = vim.fn.getregion(
    vim.fn.getpos('v'),
    vim.fn.getpos('.'),
    { type = vim.fn.mode():sub(1, 1) }
  )
  for i, line in ipairs(selection) do
    selection[i] = escape_pattern(line)
  end
  local text = table.concat(selection, '\\n')
  if text == '' then
    return nil
  end
  return '\\V' .. text
end

---Build a pattern for the word under the cursor
---@return string?
local function word_pattern()
  local word = vim.fn.expand('<cword>')
  if word == '' then
    return nil
  end
  return '\\V\\<' .. escape_pattern(word) .. '\\>'
end

---Get the pattern for the current buffer, deriving (and remembering) it from
---the word or Visual selection when needed
---@param reset? boolean rebuild the pattern even if one is cached
---@return string?
local function get_pattern(reset)
  local buf = vim.api.nvim_get_current_buf()
  if reset or not patterns[buf] or not has_cursors() then
    patterns[buf] = in_visual_mode() and selection_pattern() or word_pattern()
  end
  local pattern = patterns[buf]
  if pattern then
    -- Keep `n`/`N` and the search register in sync with the cached pattern
    vim.fn.setreg('/', pattern)
  end
  return pattern
end

---Add a cursor at the current position, then run a normal-mode motion
---@param motion string
---@param reset? boolean rebuild the search pattern first
---@return nil
local function add_cursor_and_move(motion, reset)
  if motion == 'n' or motion == 'N' then
    if not get_pattern(reset) then
      return
    end
    escape_visual()
  end

  -- A new cursor must not drag the others along
  vim.bo.follow = false

  local count = vim.v.count1
  for _ = 1, count do
    local pos = vim.api.nvim_win_get_cursor(0)
    add_cursor(pos[1] - 1, pos[2])
    if not pcall(vim.cmd, 'normal! ' .. motion) then
      break
    end
  end
end

---Place a cursor at every occurrence of the word or Visual selection
---@return nil
local function select_all()
  if not get_pattern(true) then
    return
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  escape_visual()
  -- `zq{search}` places a cursor at every match; restore the primary cursor
  -- afterwards because the search motion moves it. Follow mode would cascade
  -- the search per-cursor, so turn it off for the replay.
  local follow = vim.bo.follow
  vim.bo.follow = false
  pcall(vim.cmd, 'silent! normal! zqn')
  vim.bo.follow = follow
  vim.api.nvim_win_set_cursor(0, pos)
end

---Toggle follow mode
---@return nil
local function toggle_follow()
  vim.bo.follow = not vim.bo.follow
end

---Remove the cursor under the cursor
---@return nil
local function remove_current_cursor()
  -- `2Q` forces removal instead of toggling, so this is a no-op when there is
  -- no cursor at the current position.
  pcall(vim.cmd, 'silent! normal! 2Q')
end

---Go back to the previous cursor and remove it
---@return nil
local function remove_previous_cursor()
  if not has_cursors() then
    return
  end
  pcall(vim.cmd, 'silent! normal! [CQ')
end

---@param modes string|string[]
---@param lhs string
---@param rhs string|function
---@param desc string
---@return nil
local function map(modes, lhs, rhs, desc)
  vim.keymap.set(modes, '<M-m>' .. lhs, rhs, {
    desc = desc,
    silent = true,
  })
end

---Set up multicursor mappings
---@return nil
function M.setup()
  if vim.g.loaded_multicursor ~= nil then
    return
  end
  vim.g.loaded_multicursor = true

  map('n', 'j', function()
    add_cursor_and_move('j')
  end, 'Add a cursor and move down')

  map('n', 'k', function()
    add_cursor_and_move('k')
  end, 'Add a cursor and move up')

  map({ 'n', 'x' }, 'a', select_all, 'Add a cursor at every occurrence')

  map({ 'n', 'x' }, 'n', function()
    add_cursor_and_move('n')
  end, 'Add a cursor at the next occurrence')

  map({ 'n', 'x' }, 'N', function()
    add_cursor_and_move('N')
  end, 'Add a cursor at the previous occurrence')

  map({ 'n', 'x' }, 'r', function()
    get_pattern(true)
  end, 'Rebuild the occurrence pattern')

  map('n', 'c', clear_cursors, 'Clear all cursors')

  map('n', 'f', toggle_follow, 'Toggle multicursor follow mode')

  map('n', 'd', remove_current_cursor, 'Remove the cursor under the cursor')

  map(
    'n',
    'x',
    remove_previous_cursor,
    'Go back to the previous cursor and remove it'
  )
end

return M
