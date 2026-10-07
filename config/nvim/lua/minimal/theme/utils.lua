local M = {}

M.bg = '#0d0d0d'
M.fg = '#e0e0e0'

local function rgb(c)
  c = string.lower(c)
  return {
    tonumber(c:sub(2, 3), 16),
    tonumber(c:sub(4, 5), 16),
    tonumber(c:sub(6, 7), 16),
  }
end

function M.blend(foreground, alpha, background)
  alpha = type(alpha) == 'string' and (tonumber(alpha, 16) / 0xff) or alpha
  local bg = rgb(background)
  local fg = rgb(foreground)
  local blendChannel = function(i)
    local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end
  return string.format(
    '#%02x%02x%02x',
    blendChannel(1),
    blendChannel(2),
    blendChannel(3)
  )
end

function M.blend_bg(hex, amount, bg)
  return M.blend(hex, amount, bg or M.bg)
end

M.darken = M.blend_bg

function M.blend_fg(hex, amount, fg)
  return M.blend(hex, amount, fg or M.fg)
end

M.lighten = M.blend_fg

function M.resolve(groups)
  for _, hl in pairs(groups) do
    if type(hl.style) == 'table' then
      for k, v in pairs(hl.style) do
        hl[k] = v
      end
      hl.style = nil
    end
  end
  return groups
end

return M
