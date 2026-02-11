-- Per-window buffer line using winbar
local M = {}

-- Per-window buffer tracking: { [win_id] = {buf1, buf2, ...} }
M.win_bufs = {}

local function is_trackable(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buflisted
    and vim.bo[buf].buftype == ''
    and vim.api.nvim_buf_get_name(buf) ~= ''
end

local function get_bufs(win)
  local bufs = {}
  for _, buf in ipairs(M.win_bufs[win] or {}) do
    if is_trackable(buf) then
      table.insert(bufs, buf)
    end
  end
  M.win_bufs[win] = bufs
  return bufs
end

local function add_buf(win, buf)
  if not is_trackable(buf) then return end
  local bufs = M.win_bufs[win] or {}
  for _, b in ipairs(bufs) do
    if b == buf then return end
  end
  table.insert(bufs, buf)
  M.win_bufs[win] = bufs
end

local function remove_buf_all(buf)
  for win, bufs in pairs(M.win_bufs) do
    local new = {}
    for _, b in ipairs(bufs) do
      if b ~= buf then table.insert(new, b) end
    end
    M.win_bufs[win] = new
  end
end

local function cleanup_windows()
  local valid = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    valid[win] = true
  end
  for win in pairs(M.win_bufs) do
    if not valid[win] then
      M.win_bufs[win] = nil
    end
  end
end

-- Navigate to next buffer in current window's list
function M.next_buf()
  local win = vim.api.nvim_get_current_win()
  local bufs = get_bufs(win)
  if #bufs <= 1 then return end
  local cur = vim.api.nvim_get_current_buf()
  for i, buf in ipairs(bufs) do
    if buf == cur then
      vim.api.nvim_set_current_buf(bufs[(i % #bufs) + 1])
      return
    end
  end
end

-- Navigate to previous buffer in current window's list
function M.prev_buf()
  local win = vim.api.nvim_get_current_win()
  local bufs = get_bufs(win)
  if #bufs <= 1 then return end
  local cur = vim.api.nvim_get_current_buf()
  for i, buf in ipairs(bufs) do
    if buf == cur then
      vim.api.nvim_set_current_buf(bufs[((i - 2) % #bufs) + 1])
      return
    end
  end
end

-- Close current buffer (remove from all windows, delete it)
function M.close_buf()
  local win = vim.api.nvim_get_current_win()
  local bufs = get_bufs(win)
  local cur = vim.api.nvim_get_current_buf()

  -- Switch to another buffer in this window first
  if #bufs > 1 then
    for i, buf in ipairs(bufs) do
      if buf == cur then
        local next_i = (i % #bufs) + 1
        vim.api.nvim_set_current_buf(bufs[next_i])
        break
      end
    end
  end

  remove_buf_all(cur)
  vim.cmd('bdelete! ' .. cur)
end

-- Render winbar for a specific window
local function update_winbar(win)
  if not vim.api.nvim_win_is_valid(win) then return end

  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= '' then
    pcall(function() vim.wo[win].winbar = '' end)
    return
  end

  local bufs = get_bufs(win)
  if #bufs <= 1 then
    pcall(function() vim.wo[win].winbar = '' end)
    return
  end

  local cur = vim.api.nvim_win_get_buf(win)
  local parts = {}
  for i, b in ipairs(bufs) do
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ':t')
    local mod = vim.bo[b].modified and ' [+]' or ''
    local sep = (i < #bufs) and ' │ ' or ''
    if b == cur then
      table.insert(parts, '%#TabLineSel# ' .. name .. mod .. ' %#TabLine#' .. sep)
    else
      table.insert(parts, ' ' .. name .. mod .. ' ' .. sep)
    end
  end

  pcall(function() vim.wo[win].winbar = table.concat(parts) end)
end

local function update_all_winbars()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    update_winbar(win)
  end
end

function M.setup()
  -- Disable global tabline, use per-window winbar instead
  vim.opt.showtabline = 0

  local group = vim.api.nvim_create_augroup('PerWindowBufferLine', { clear = true })

  -- Track buffers entering windows
  vim.api.nvim_create_autocmd({'BufWinEnter', 'BufEnter'}, {
    group = group,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_get_current_buf()
      add_buf(win, buf)
      update_all_winbars()
    end,
  })

  -- Clean up deleted buffers
  vim.api.nvim_create_autocmd({'BufDelete', 'BufWipeout'}, {
    group = group,
    callback = function(args)
      remove_buf_all(args.buf)
      vim.schedule(update_all_winbars)
    end,
  })

  -- Update on save/modify for [+] indicator
  vim.api.nvim_create_autocmd({'BufModifiedSet', 'BufWritePost'}, {
    group = group,
    callback = update_all_winbars,
  })

  -- Clean up closed windows
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function()
      vim.schedule(function()
        cleanup_windows()
        update_all_winbars()
      end)
    end,
  })
end

return M
