-- Terminal integration module
local M = {}

-- State
M.terminals = {}
M.current_terminal = 1
M.win = nil

-- Private helper functions
local function jump_to_editor()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_option(buf, 'buftype') ~= 'terminal' then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end

local function set_terminal_name(buf, index, job_id)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  
  local name = 'Terminal-' .. index
  local success = pcall(vim.api.nvim_buf_set_name, buf, name)
  if not success then
    -- If naming fails, try with unique suffix
    name = name .. '-' .. job_id
    pcall(vim.api.nvim_buf_set_name, buf, name)
  end
end

local function create_terminal_buffer(index)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  
  vim.api.nvim_buf_call(buf, function()
    local job_id = vim.fn.termopen(vim.o.shell)
    vim.defer_fn(function()
      set_terminal_name(buf, index, job_id)
    end, 100)
  end)
  
  return buf
end

local function show_terminal_info()
  local total = #M.terminals
  if total == 0 then
    print("No terminals")
    return
  end
  
  local msg = string.format("Terminal %d/%d", M.current_terminal, total)
  print(msg)
  vim.defer_fn(function() vim.cmd('echo ""') end, 2000)
end

-- Public API
function M.get_or_create(index)
  index = index or M.current_terminal
  
  if not M.terminals[index] or not vim.api.nvim_buf_is_valid(M.terminals[index]) then
    M.terminals[index] = create_terminal_buffer(index)
  end
  
  return M.terminals[index]
end

function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_hide(M.win)
    M.win = nil
  else
    local buf = M.get_or_create()
    
    vim.cmd('botright split')
    M.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(M.win, math.floor(vim.o.lines * 0.3))
    vim.api.nvim_win_set_buf(M.win, buf)
    
    -- Ensure line numbers are disabled for this terminal window
    vim.api.nvim_win_set_option(M.win, 'number', false)
    vim.api.nvim_win_set_option(M.win, 'relativenumber', false)
    vim.api.nvim_win_set_option(M.win, 'signcolumn', 'no')
    
    vim.cmd('startinsert')
  end
end

function M.float()
  local buf = M.get_or_create()
  
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  M.win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Ensure line numbers are disabled for this floating terminal window
  vim.api.nvim_win_set_option(M.win, 'number', false)
  vim.api.nvim_win_set_option(M.win, 'relativenumber', false)
  vim.api.nvim_win_set_option(M.win, 'signcolumn', 'no')
  
  vim.cmd('startinsert')
end

function M.new()
  local new_index = #M.terminals + 1
  M.current_terminal = new_index
  
  local buf = M.get_or_create(new_index)
  
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_set_buf(M.win, buf)
    vim.cmd('startinsert')
  else
    M.toggle()
  end
end

function M.close_and_jump()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Remove from terminals array
  for i, buf in ipairs(M.terminals) do
    if buf == current_buf then
      table.remove(M.terminals, i)
      -- Adjust current index
      if M.current_terminal > #M.terminals and #M.terminals > 0 then
        M.current_terminal = #M.terminals
      elseif #M.terminals == 0 then
        M.current_terminal = 1
      end
      break
    end
  end
  
  -- Hide window and delete buffer
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_hide(M.win)
    M.win = nil
  end
  
  vim.api.nvim_buf_delete(current_buf, { force = true })
  jump_to_editor()
end

function M.next()
  if #M.terminals == 0 then
    M.new()
    return
  end
  
  M.current_terminal = M.current_terminal + 1
  if M.current_terminal > #M.terminals then
    M.current_terminal = 1
  end
  
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    local buf = M.get_or_create()
    vim.api.nvim_win_set_buf(M.win, buf)
    
    if vim.api.nvim_get_current_win() == M.win then
      vim.cmd('startinsert')
    end
    show_terminal_info()
  else
    M.toggle()
  end
end

function M.prev()
  if #M.terminals == 0 then
    M.new()
    return
  end
  
  M.current_terminal = M.current_terminal - 1
  if M.current_terminal < 1 then
    M.current_terminal = #M.terminals
  end
  
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    local buf = M.get_or_create()
    vim.api.nvim_win_set_buf(M.win, buf)
    
    if vim.api.nvim_get_current_win() == M.win then
      vim.cmd('startinsert')
    end
    show_terminal_info()
  else
    M.toggle()
  end
end

-- Open yazi file manager in floating window
function M.yazi()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' yazi ',
    title_pos = 'center'
  })
  
  -- Disable line numbers for this buffer specifically
  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)
  
  -- Create temporary file for yazi to write selected files
  local tmp_file = vim.fn.tempname()
  
  -- Start yazi with chooser option
  vim.fn.termopen(string.format('yazi --chooser-file=%s', tmp_file), {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      
      -- Read selected files and open them
      if vim.fn.filereadable(tmp_file) == 1 then
        local file_content = vim.fn.readfile(tmp_file)
        for _, file_path in ipairs(file_content) do
          if file_path ~= "" then
            vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
          end
        end
        vim.fn.delete(tmp_file)
      end
    end
  })
  
  vim.cmd('startinsert')
end

function M.clear_terminal()
  if vim.bo.buftype == 'terminal' then
    -- Get current terminal info
    local current_buf = vim.api.nvim_get_current_buf()
    local current_win = vim.api.nvim_get_current_win()

    -- Find which terminal index this is
    local terminal_index = M.current_terminal
    for i, buf in ipairs(M.terminals) do
      if buf == current_buf then
        terminal_index = i
        break
      end
    end

    -- Create a new clean terminal buffer first
    local new_buf = create_terminal_buffer(terminal_index)

    -- Set the new buffer in the window
    vim.api.nvim_win_set_buf(current_win, new_buf)

    -- Update our terminals array
    M.terminals[terminal_index] = new_buf

    -- Now delete the old buffer
    vim.api.nvim_buf_delete(current_buf, { force = true })

    -- Enter insert mode without triggering extra characters
    vim.schedule(function()
      if vim.api.nvim_get_current_buf() == new_buf then
        vim.cmd('startinsert')
      end
    end)

    print("Terminal cleared")
  else
    print("Not in a terminal buffer")
  end
end

function M.setup()
  -- Terminal configuration autocmds
  vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*',
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local win = vim.api.nvim_get_current_win()
      
      -- Always disable line numbers for terminal buffers
      vim.cmd('setlocal nonumber norelativenumber signcolumn=no')
      vim.api.nvim_buf_set_option(buf, 'number', false)
      vim.api.nvim_buf_set_option(buf, 'relativenumber', false)
      vim.api.nvim_buf_set_option(buf, 'signcolumn', 'no')
      vim.api.nvim_win_set_option(win, 'number', false)
      vim.api.nvim_win_set_option(win, 'relativenumber', false)
      vim.api.nvim_win_set_option(win, 'signcolumn', 'no')
      
      vim.cmd('startinsert')
    end,
  })

  vim.api.nvim_create_autocmd('TermClose', {
    pattern = '*',
    callback = function()
      -- Only auto-delete terminals that are part of our terminal management
      local buf = vim.api.nvim_get_current_buf()
      local buf_name = vim.api.nvim_buf_get_name(buf)
      
      -- Don't auto-delete fzf or other temporary terminals
      if string.match(buf_name, 'Terminal%-') then
        vim.cmd('bdelete!')
      end
    end,
  })

  -- Ensure line numbers are restored for non-terminal buffers
  vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter'}, {
    pattern = '*',
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local win = vim.api.nvim_get_current_win()
      
      if vim.bo[buf].buftype == 'terminal' then
        -- Force disable line numbers for terminal buffers
        vim.wo[win].number = false
        vim.wo[win].relativenumber = false
        vim.wo[win].signcolumn = 'no'
      else
        -- Restore line numbers for non-terminal buffers
        vim.wo[win].number = true
        vim.wo[win].relativenumber = true
      end
    end,
  })
  
  -- Keymaps
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
  end

  -- Normal mode - terminal management
  map('n', '<leader>tt', M.toggle, 'Toggle terminal')
  map('n', '<leader>tf', M.float, 'Float terminal')
  map('n', '<leader>tn', M.new, 'New terminal')
  map('n', '<leader>]', M.next, 'Next terminal')
  map('n', '<leader>[', M.prev, 'Previous terminal')
  map('n', '<leader>e', M.yazi, 'Open yazi file manager')

  -- Terminal mode - NO leader bindings (they intercept typing)
  -- Use Ctrl-based bindings that don't conflict with normal typing
  map('t', '<Esc>', '<C-\\><C-n>', 'Exit terminal mode')
  map('t', '<C-\\><C-x>', '<C-\\><C-n>:lua require("terminal").close_and_jump()<CR>', 'Close terminal')
  map('t', '<C-\\><C-t>', '<C-\\><C-n>:lua require("terminal").toggle()<CR>', 'Toggle terminal')
  map('t', '<C-\\><C-]>', '<C-\\><C-n>:lua require("terminal").next()<CR>', 'Next terminal')
  map('t', '<C-\\><C-[>', '<C-\\><C-n>:lua require("terminal").prev()<CR>', 'Previous terminal')
  map('t', '<C-\\><C-c>', '<C-\\><C-n>:lua require("terminal").clear_terminal()<CR>i', 'Clear terminal')

  -- Window navigation from terminal (Ctrl-based, standard)
  map('t', '<C-h>', '<C-\\><C-n><C-w>h', 'Move to left window')
  map('t', '<C-j>', '<C-\\><C-n><C-w>j', 'Move to bottom window')
  map('t', '<C-k>', '<C-\\><C-n><C-w>k', 'Move to top window')
  map('t', '<C-l>', '<C-\\><C-n><C-w>l', 'Move to right window')
end

return M