-- Search module using fzf in popup windows
local M = {}

-- Helper function to create floating window
local function create_float_window(title)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'number', false)
  vim.api.nvim_buf_set_option(buf, 'relativenumber', false)
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. title .. ' ',
    title_pos = 'center'
  })
  
  -- Add escape key mapping to close window
  vim.api.nvim_buf_set_keymap(buf, 't', '<Esc>', '<C-\\><C-n>:close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 't', '<C-c>', '<C-\\><C-n>:close<CR>', { noremap = true, silent = true })
  
  return buf, win
end

-- Helper function to handle file selection
local function handle_file_selection(selection)
  if selection and selection ~= '' then
    -- Extract filename (before colon if it has line numbers)
    local filename = selection:match('^([^:]+)')
    if filename then
      vim.cmd('edit ' .. vim.fn.fnameescape(filename))
      
      -- If there's a line number, jump to it
      local line = selection:match('^[^:]+:(%d+)')
      if line then
        vim.cmd('normal! ' .. line .. 'G')
      end
    end
  end
end

-- Find files using fd + fzf
function M.find_files()
  local buf, win = create_float_window('Find Files')
  
  local cmd = vim.fn.executable('fd') == 1 and 'fd --type f' or 'find . -type f'
  local temp_file = vim.fn.tempname()
  local full_cmd = cmd .. ' | fzf --prompt="Files> " --preview="head -50 {}" > ' .. temp_file
  
  vim.fn.termopen(full_cmd, {
    on_exit = function(_, exit_code)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
        
        if exit_code == 0 then
          -- Read the selection from temp file
          local selection = vim.fn.readfile(temp_file)[1]
          vim.fn.delete(temp_file)
          
          if selection and selection ~= '' then
            vim.schedule(function()
              handle_file_selection(selection)
            end)
          end
        else
          vim.fn.delete(temp_file)
        end
      end
    end
  })
  
  vim.cmd('startinsert')
end

-- Search content using rg + fzf
function M.grep_content()
  local pattern = vim.fn.input('Search pattern: ')
  if pattern == '' then return end
  
  local buf, win = create_float_window('Grep: ' .. pattern)
  local temp_file = vim.fn.tempname()
  
  local cmd = 'rg --line-number --column --color=always --smart-case "' .. pattern .. '" | fzf --ansi --prompt="Grep> " --delimiter=: --preview="bat --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}" > ' .. temp_file
  
  vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
        
        if exit_code == 0 then
          local selection = vim.fn.readfile(temp_file)[1]
          vim.fn.delete(temp_file)
          
          if selection and selection ~= '' then
            vim.schedule(function()
              handle_file_selection(selection)
            end)
          end
        else
          vim.fn.delete(temp_file)
        end
      end
    end
  })
  
  vim.cmd('startinsert')
end

-- Search for word under cursor
function M.grep_word()
  local word = vim.fn.expand('<cword>')
  if word == '' then return end
  
  local buf, win = create_float_window('Grep Word: ' .. word)
  local temp_file = vim.fn.tempname()
  
  local cmd = 'rg --line-number --column --color=always --smart-case --word-regexp "' .. word .. '" | fzf --ansi --prompt="Word> " --delimiter=: --preview="bat --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}" > ' .. temp_file
  
  vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
        
        if exit_code == 0 then
          local selection = vim.fn.readfile(temp_file)[1]
          vim.fn.delete(temp_file)
          
          if selection and selection ~= '' then
            vim.schedule(function()
              handle_file_selection(selection)
            end)
          end
        else
          vim.fn.delete(temp_file)
        end
      end
    end
  })
  
  vim.cmd('startinsert')
end

-- Search by file type
function M.grep_filetype()
  local filetype = vim.fn.input('File type (js, py, lua, etc): ')
  if filetype == '' then return end
  
  local pattern = vim.fn.input('Search pattern: ')
  if pattern == '' then return end
  
  local buf, win = create_float_window('Grep ' .. filetype .. ': ' .. pattern)
  local temp_file = vim.fn.tempname()
  
  local cmd = 'rg --line-number --column --color=always --smart-case --type ' .. filetype .. ' "' .. pattern .. '" | fzf --ansi --prompt="' .. filetype .. '> " --delimiter=: --preview="bat --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}" > ' .. temp_file
  
  vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
        
        if exit_code == 0 then
          local selection = vim.fn.readfile(temp_file)[1]
          vim.fn.delete(temp_file)
          
          if selection and selection ~= '' then
            vim.schedule(function()
              handle_file_selection(selection)
            end)
          end
        else
          vim.fn.delete(temp_file)
        end
      end
    end
  })
  
  vim.cmd('startinsert')
end

function M.setup()
  -- Search keymaps
  vim.keymap.set('n', '<leader>ff', M.find_files, { desc = 'Find files' })
  vim.keymap.set('n', '<leader>fg', M.grep_content, { desc = 'Grep content' })
  vim.keymap.set('n', '<leader>fw', M.grep_word, { desc = 'Grep word under cursor' })
  vim.keymap.set('n', '<leader>ft', M.grep_filetype, { desc = 'Grep by file type' })
end

return M