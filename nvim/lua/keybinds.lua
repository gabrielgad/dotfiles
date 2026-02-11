-- Keybind viewer module
local M = {}

-- State
M.buf = nil
M.win = nil

-- Helper function to format key display
local function format_key(key)
  -- Replace common key representations with more readable versions
  key = key:gsub('<leader>', 'SPC')
  key = key:gsub('<C%-', 'Ctrl+')
  key = key:gsub('<S%-', 'Shift+')
  key = key:gsub('<A%-', 'Alt+')
  key = key:gsub('<M%-', 'Meta+')
  key = key:gsub('>', '')
  return key
end

-- Helper function to get mode display name
local function get_mode_name(mode)
  local mode_names = {
    n = 'NORMAL',
    i = 'INSERT', 
    v = 'VISUAL',
    x = 'VISUAL-BLOCK',
    s = 'SELECT',
    o = 'OPERATOR',
    t = 'TERMINAL',
    c = 'COMMAND',
    [''] = 'GLOBAL',  -- Global keymaps (no specific mode)
  }
  return mode_names[mode] or mode:upper()
end

-- Check if a keymap is user-defined
local function is_user_keymap(keymap)
  -- Has description (user keymaps usually have descriptions)
  if keymap.desc and keymap.desc ~= "" then
    return true
  end
  
  -- Contains leader key
  if keymap.lhs:match("<leader>") or keymap.lhs:match(" ") then
    return true
  end
  
  -- Common user-defined patterns
  if keymap.lhs:match("^<C%-") or keymap.lhs:match("^<A%-") or keymap.lhs:match("^<M%-") then
    -- But exclude some common built-ins
    local builtin_ctrl_keys = {
      "<C-n>", "<C-p>", "<C-u>", "<C-d>", "<C-f>", "<C-b>",
      "<C-w>", "<C-r>", "<C-o>", "<C-i>", "<C-a>", "<C-x>",
      "<C-g>", "<C-l>", "<C-h>", "<C-j>", "<C-k>", "<C-v>",
      "<C-c>", "<C-z>", "<C-s>", "<C-q>"
    }
    
    for _, builtin in ipairs(builtin_ctrl_keys) do
      if keymap.lhs == builtin then
        return false
      end
    end
    return true
  end
  
  -- Function keys are usually user-defined
  if keymap.lhs:match("^<F%d+>") then
    return true
  end
  
  -- Multi-character keys that aren't common vim bindings
  if #keymap.lhs > 1 and not keymap.lhs:match("^<.*>$") then
    return true
  end
  
  return false
end

-- Get all keymaps and format them
local function get_formatted_keymaps()
  local lines = {}
  local user_keymaps = {}
  local builtin_keymaps = {}
  
  -- Collect all keymaps
  local all_keymaps = {}
  local seen_keymaps = {}  -- Track duplicates
  
  -- Get keymaps for all modes (skip global to avoid duplicates)
  local modes = {'n', 'i', 'v', 'x', 't', 'c', 'o', 's'}
  for _, mode in ipairs(modes) do
    local mode_keymaps = vim.api.nvim_get_keymap(mode)
    for _, keymap in ipairs(mode_keymaps) do
      local key_id = mode .. ':' .. keymap.lhs
      
      -- Only add if we haven't seen this exact keymap before
      if not seen_keymaps[key_id] then
        keymap.mode = mode
        table.insert(all_keymaps, keymap)
        seen_keymaps[key_id] = true
      end
    end
    
    -- Also get buffer-local keymaps for this mode
    local buf_mode_keymaps = vim.api.nvim_buf_get_keymap(0, mode)
    for _, keymap in ipairs(buf_mode_keymaps) do
      local key_id = mode .. ':buf:' .. keymap.lhs
      
      if not seen_keymaps[key_id] then
        keymap.mode = mode
        keymap.buffer_local = true
        table.insert(all_keymaps, keymap)
        seen_keymaps[key_id] = true
      end
    end
  end
  
  -- Separate user and built-in keymaps
  for _, keymap in ipairs(all_keymaps) do
    -- Skip some internal/default keymaps to reduce noise
    if keymap.lhs:match("^<Plug>") or keymap.lhs:match("^<SNR>") then
      goto continue
    end
    
    if is_user_keymap(keymap) then
      table.insert(user_keymaps, keymap)
    else
      table.insert(builtin_keymaps, keymap)
    end
    
    ::continue::
  end
  
  -- Sort function
  local function sort_keymaps(a, b)
    if a.mode ~= b.mode then
      return a.mode < b.mode
    end
    return a.lhs < b.lhs
  end
  
  table.sort(user_keymaps, sort_keymaps)
  table.sort(builtin_keymaps, sort_keymaps)
  
  -- Add header
  table.insert(lines, "═══════════════════════════════════════════════════════════════")
  table.insert(lines, "                        NEOVIM KEYBINDS")
  table.insert(lines, "═══════════════════════════════════════════════════════════════")
  table.insert(lines, "")
  table.insert(lines, "Use / to search, q to quit, <Esc> to close")
  table.insert(lines, "")
  
  -- Add user keymaps section
  table.insert(lines, "┌─────────────────────────────────────────────────────────────┐")
  table.insert(lines, "│                      USER KEYBINDS                          │")
  table.insert(lines, "└─────────────────────────────────────────────────────────────┘")
  table.insert(lines, "")
  table.insert(lines, string.format("%-8s %-20s %s", "MODE", "KEY", "DESCRIPTION"))
  table.insert(lines, "───────────────────────────────────────────────────────────────")
  
  -- Format user keymaps
  local current_mode = ""
  for _, keymap in ipairs(user_keymaps) do
    local mode = get_mode_name(keymap.mode)
    local key = format_key(keymap.lhs)
    local desc = keymap.desc or keymap.rhs or "No description"
    
    -- Add buffer-local indicator
    if keymap.buffer_local then
      desc = "[buf] " .. desc
    end
    
    -- Add spacing between different modes
    if mode ~= current_mode then
      if current_mode ~= "" then
        table.insert(lines, "")
      end
      current_mode = mode
    end
    
    -- Truncate long descriptions
    if #desc > 45 then
      desc = desc:sub(1, 42) .. "..."
    end
    
    local line = string.format("%-8s %-20s %s", mode, key, desc)
    table.insert(lines, line)
  end
  
  -- Add built-in keymaps section
  table.insert(lines, "")
  table.insert(lines, "")
  table.insert(lines, "┌─────────────────────────────────────────────────────────────┐")
  table.insert(lines, "│                    BUILT-IN KEYBINDS                        │")
  table.insert(lines, "└─────────────────────────────────────────────────────────────┘")
  table.insert(lines, "")
  table.insert(lines, string.format("%-8s %-20s %s", "MODE", "KEY", "DESCRIPTION"))
  table.insert(lines, "───────────────────────────────────────────────────────────────")
  
  -- Format built-in keymaps (limit to most useful ones)
  current_mode = ""
  local count = 0
  local max_builtins = 50  -- Limit built-ins to avoid clutter
  
  for _, keymap in ipairs(builtin_keymaps) do
    if count >= max_builtins then break end
    
    local mode = get_mode_name(keymap.mode)
    local key = format_key(keymap.lhs)
    local desc = keymap.desc or keymap.rhs or "Built-in"
    
    -- Add spacing between different modes
    if mode ~= current_mode then
      if current_mode ~= "" then
        table.insert(lines, "")
      end
      current_mode = mode
    end
    
    -- Truncate long descriptions
    if #desc > 45 then
      desc = desc:sub(1, 42) .. "..."
    end
    
    local line = string.format("%-8s %-20s %s", mode, key, desc)
    table.insert(lines, line)
    count = count + 1
  end
  
  if #builtin_keymaps > max_builtins then
    table.insert(lines, "")
    table.insert(lines, string.format("... and %d more built-in keybinds", #builtin_keymaps - max_builtins))
  end
  
  return lines
end

-- Create the keybind buffer
local function create_keybind_buffer()
  M.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(M.buf, 'Keybinds')
  vim.api.nvim_buf_set_option(M.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(M.buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(M.buf, 'bufhidden', 'wipe')
  
  -- Get formatted keymaps
  local lines = get_formatted_keymaps()
  
  -- Set buffer content (while it's still modifiable)
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  
  -- Now make it readonly to prevent editing
  vim.api.nvim_buf_set_option(M.buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(M.buf, 'readonly', true)
  
  -- Set buffer keymaps
  local opts = { buffer = M.buf, silent = true }
  vim.keymap.set('n', 'q', function() M.close() end, opts)
  vim.keymap.set('n', '<Esc>', function() M.close() end, opts)
  vim.keymap.set('n', '<CR>', function() M.close() end, opts)
  
  return M.buf
end

-- Toggle keybind viewer
function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    M.close()
  else
    M.open()
  end
end

-- Open keybind viewer
function M.open()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    create_keybind_buffer()
  else
    -- Refresh content
    local lines = get_formatted_keymaps()
    
    -- Temporarily allow modification without showing readonly warning
    local original_readonly = vim.api.nvim_buf_get_option(M.buf, 'readonly')
    vim.api.nvim_buf_set_option(M.buf, 'readonly', false)
    vim.api.nvim_buf_set_option(M.buf, 'modifiable', true)
    
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
    
    -- Restore readonly state
    vim.api.nvim_buf_set_option(M.buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(M.buf, 'readonly', original_readonly)
  end
  
  -- Create floating window
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  M.win = vim.api.nvim_open_win(M.buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Keybinds ',
    title_pos = 'center'
  })
  
  -- Set window options
  vim.api.nvim_win_set_option(M.win, 'wrap', false)
  vim.api.nvim_win_set_option(M.win, 'cursorline', true)
end

-- Close keybind viewer
function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
  end
end

-- Setup function
function M.setup()
  -- Keybinds are now handled by mappings.lua
  -- This module just provides the viewer functionality
end

return M
