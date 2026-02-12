-- Window-scoped buffer line implementation
local M = {}

-- Track which buffers belong to which window
-- Key: window id, Value: { buf1, buf2, ... }
M.win_buffers = {}

-- Check if buffer is valid for display
local function is_valid_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  if not vim.api.nvim_buf_is_loaded(buf) then return false end
  if not vim.api.nvim_buf_get_option(buf, 'buflisted') then return false end
  if vim.api.nvim_buf_get_name(buf) == '' then return false end

  local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
  if buftype == 'terminal' or buftype == 'nofile' or buftype == 'quickfix' or buftype == 'help' then
    return false
  end

  return true
end

-- Initialize window buffer list if needed
local function ensure_win_exists(winid)
  if not M.win_buffers[winid] then
    M.win_buffers[winid] = {}
  end
end

-- Add buffer to window's scope
local function add_buffer_to_win(buf, winid)
  winid = winid or vim.api.nvim_get_current_win()
  if not is_valid_buffer(buf) then return end

  ensure_win_exists(winid)

  -- Check if buffer is already in this window
  for _, b in ipairs(M.win_buffers[winid]) do
    if b == buf then return end
  end

  table.insert(M.win_buffers[winid], buf)
end

-- Remove buffer from window's scope
local function remove_buffer_from_win(buf, winid)
  if not M.win_buffers[winid] then return end

  for i, b in ipairs(M.win_buffers[winid]) do
    if b == buf then
      table.remove(M.win_buffers[winid], i)
      return
    end
  end
end

-- Remove buffer from all windows (when deleted)
local function remove_buffer_from_all_wins(buf)
  for winid, _ in pairs(M.win_buffers) do
    remove_buffer_from_win(buf, winid)
  end
end

-- Clean up invalid buffers from a window
local function clean_win_buffers(winid)
  if not M.win_buffers[winid] then return end

  local valid_bufs = {}
  for _, buf in ipairs(M.win_buffers[winid]) do
    if is_valid_buffer(buf) then
      table.insert(valid_bufs, buf)
    end
  end
  M.win_buffers[winid] = valid_bufs
end

-- Get buffer list for current window
local function get_win_buffers(winid)
  winid = winid or vim.api.nvim_get_current_win()
  ensure_win_exists(winid)
  clean_win_buffers(winid)
  return M.win_buffers[winid]
end

-- Create winbar string for a window
local function create_winbar(winid)
  local bufs = get_win_buffers(winid)
  if #bufs <= 1 then return '' end

  local current_buf = vim.api.nvim_win_get_buf(winid)
  local parts = {}

  for i, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    local filename = vim.fn.fnamemodify(name, ':t')
    local modified = vim.api.nvim_buf_get_option(buf, 'modified')
    local display = filename .. (modified and ' [+]' or '')
    local separator = (i < #bufs) and ' │ ' or ''

    if buf == current_buf then
      table.insert(parts, '%#TabLineSel# ' .. display .. ' %#TabLine#' .. separator)
    else
      table.insert(parts, ' ' .. display .. ' ' .. separator)
    end
  end

  return table.concat(parts)
end

-- Update winbar for current window
local function update_winbar()
  local winid = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(winid)

  -- Skip terminal and special buffers
  local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
  if buftype == 'terminal' or buftype == 'nofile' or buftype == 'quickfix' or buftype == 'help' then
    vim.wo[winid].winbar = nil
    return
  end

  local bufs = get_win_buffers(winid)
  if #bufs > 1 then
    vim.wo[winid].winbar = create_winbar(winid)
  else
    vim.wo[winid].winbar = nil
  end
end

-- Update all windows
local function update_all_winbars()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) then
      local buf = vim.api.nvim_win_get_buf(winid)
      local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
      if buftype ~= 'terminal' and buftype ~= 'nofile' then
        local bufs = get_win_buffers(winid)
        if #bufs > 1 then
          vim.wo[winid].winbar = create_winbar(winid)
        else
          vim.wo[winid].winbar = nil
        end
      end
    end
  end
end

-- Navigate to next buffer in current window
function M.next_buffer()
  local winid = vim.api.nvim_get_current_win()
  local bufs = get_win_buffers(winid)
  if #bufs <= 1 then return end

  local current_buf = vim.api.nvim_get_current_buf()
  for i, buf in ipairs(bufs) do
    if buf == current_buf then
      local next_idx = (i % #bufs) + 1
      vim.api.nvim_set_current_buf(bufs[next_idx])
      return
    end
  end
end

-- Navigate to previous buffer in current window
function M.prev_buffer()
  local winid = vim.api.nvim_get_current_win()
  local bufs = get_win_buffers(winid)
  if #bufs <= 1 then return end

  local current_buf = vim.api.nvim_get_current_buf()
  for i, buf in ipairs(bufs) do
    if buf == current_buf then
      local prev_idx = ((i - 2) % #bufs) + 1
      vim.api.nvim_set_current_buf(bufs[prev_idx])
      return
    end
  end
end

-- Close current buffer in current window
function M.close_buffer()
  local winid = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  local bufs = get_win_buffers(winid)

  -- Find next buffer to switch to
  local next_buf = nil
  for i, buf in ipairs(bufs) do
    if buf == current_buf then
      if bufs[i + 1] then
        next_buf = bufs[i + 1]
      elseif bufs[i - 1] then
        next_buf = bufs[i - 1]
      end
      break
    end
  end

  -- Remove from this window's scope
  remove_buffer_from_win(current_buf, winid)

  -- Switch to next buffer or create empty
  if next_buf then
    vim.api.nvim_set_current_buf(next_buf)
  else
    vim.cmd('enew')
  end

  -- Delete the buffer
  vim.api.nvim_buf_delete(current_buf, { force = true })
  update_winbar()
end

function M.setup()
  -- Disable global tabline
  vim.opt.showtabline = 0

  local group = vim.api.nvim_create_augroup('WinScopedBufferLine', { clear = true })

  -- Add buffer to current window when entering
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(args)
      local buf = args.buf
      local winid = vim.api.nvim_get_current_win()
      if is_valid_buffer(buf) then
        add_buffer_to_win(buf, winid)
      end
      update_winbar()
    end
  })

  -- Update on buffer write
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    callback = update_all_winbars
  })

  -- Remove buffer when deleted
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = group,
    callback = function(args)
      remove_buffer_from_all_wins(args.buf)
      update_all_winbars()
    end
  })

  -- Clean up when window closes
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function(args)
      local winid = tonumber(args.match)
      if winid and M.win_buffers[winid] then
        M.win_buffers[winid] = nil
      end
    end
  })

  -- Update on window enter
  vim.api.nvim_create_autocmd('WinEnter', {
    group = group,
    callback = update_winbar
  })

  -- Initialize current buffer in current window
  local buf = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  if is_valid_buffer(buf) then
    add_buffer_to_win(buf, winid)
  end
end

return M
