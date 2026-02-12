-- Search module using fzf in popup windows
local M = {}

-- Normalize paths for bash (backslashes → forward slashes)
local function bp(path)
  return path:gsub('\\', '/')
end

-- Helper function to create floating window
local function create_float_window(title)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'

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

  -- Normal mode close (for when terminal loses focus)
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })

  -- Override global terminal-mode window-nav mappings so they pass through to fzf
  vim.api.nvim_buf_set_keymap(buf, 't', '<C-j>', '<C-j>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 't', '<C-k>', '<C-k>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 't', '<C-h>', '<C-h>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 't', '<C-l>', '<C-l>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 't', '<C-n>', '<C-n>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 't', '<C-p>', '<C-p>', { noremap = true, silent = true })

  return buf, win
end

-- Handle --expect output: line 1 = key, line 2 = selection
local function handle_fzf_result(temp_file)
  if vim.fn.filereadable(temp_file) ~= 1 then return end

  local lines = vim.fn.readfile(temp_file)
  vim.fn.delete(temp_file)

  local key = lines[1] or ''
  local selection = lines[2] or ''

  if key == 'ctrl-c' or key == 'ctrl-g' or key == 'ctrl-d' then return end
  if selection == '' then return end

  local filename = selection:match('^([^:]+)')
  if filename then
    vim.schedule(function()
      vim.cmd('edit ' .. vim.fn.fnameescape(filename))
      local line = selection:match('^[^:]+:(%d+)')
      if line then
        vim.cmd('normal! ' .. line .. 'G')
      end
    end)
  end
end

-- Run fzf with streaming results via start:reload (no input file needed).
-- Avoids the old pipe pattern that caused SIGINT on arrow keys in nvim terminal.
-- fzf manages its own subprocess for gathering, so stdin stays as keyboard.
local function run_fzf(buf, win, fzf_cmd, output_file, origin_win)
  local cmd = string.format("%s > '%s'", fzf_cmd, bp(output_file))

  vim.fn.termopen({vim.o.shell, '-c', cmd}, {
    on_exit = function(_, exit_code)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end

      -- Return to the window the user was in before fzf
      if origin_win and vim.api.nvim_win_is_valid(origin_win) then
        vim.api.nvim_set_current_win(origin_win)
      end

      if exit_code == 0 then
        handle_fzf_result(output_file)
      else
        vim.fn.delete(output_file)
      end
    end
  })

  vim.cmd('startinsert')
end

-- Common fzf flags
local expect = '--expect=ctrl-c,ctrl-g,ctrl-d'
local preview_toggle = "--bind 'ctrl-/:toggle-preview'"

-- Find files using fd + fzf
function M.find_files()
  local origin_win = vim.api.nvim_get_current_win()
  local buf, win = create_float_window('Find Files')
  local output_file = vim.fn.tempname()

  local find_cmd = vim.fn.executable('fd') == 1 and 'fd --type f' or 'find . -type f'
  local fzf_cmd = string.format(
    "fzf --bind 'start:reload:%s' --layout=reverse --prompt='Files> ' %s --preview 'bat --color=always --line-range :50 {}' %s",
    find_cmd, expect, preview_toggle)

  run_fzf(buf, win, fzf_cmd, output_file, origin_win)
end

-- Search content using rg + fzf
function M.grep_content()
  local pattern = vim.fn.input('Search pattern: ')
  if pattern == '' then return end

  local origin_win = vim.api.nvim_get_current_win()
  local buf, win = create_float_window('Grep: ' .. pattern)
  local output_file = vim.fn.tempname()

  local rg_cmd = string.format('rg --line-number --column --color=always --smart-case "%s"', pattern:gsub('"', '\\"'))
  local fzf_cmd = string.format(
    "fzf --bind 'start:reload:%s' --ansi --layout=reverse --prompt='Grep> ' --delimiter=: %s --preview 'bat --color=always --highlight-line {2} {1}' --preview-window='right:60%%:+{2}-/2' %s",
    rg_cmd, expect, preview_toggle)

  run_fzf(buf, win, fzf_cmd, output_file, origin_win)
end

-- Search for word under cursor
function M.grep_word()
  local origin_win = vim.api.nvim_get_current_win()
  local word = vim.fn.expand('<cword>')
  if word == '' then return end

  local buf, win = create_float_window('Grep Word: ' .. word)
  local output_file = vim.fn.tempname()

  local rg_cmd = string.format('rg --line-number --column --color=always --smart-case --word-regexp "%s"', word:gsub('"', '\\"'))
  local fzf_cmd = string.format(
    "fzf --bind 'start:reload:%s' --ansi --layout=reverse --prompt='Word> ' --delimiter=: %s --preview 'bat --color=always --highlight-line {2} {1}' --preview-window='right:60%%:+{2}-/2' %s",
    rg_cmd, expect, preview_toggle)

  run_fzf(buf, win, fzf_cmd, output_file, origin_win)
end

-- Search by file type
function M.grep_filetype()
  local filetype = vim.fn.input('File type (js, py, lua, etc): ')
  if filetype == '' then return end

  local pattern = vim.fn.input('Search pattern: ')
  if pattern == '' then return end

  local origin_win = vim.api.nvim_get_current_win()
  local buf, win = create_float_window('Grep ' .. filetype .. ': ' .. pattern)
  local output_file = vim.fn.tempname()

  local rg_cmd = string.format('rg --line-number --column --color=always --smart-case --type %s "%s"', filetype, pattern:gsub('"', '\\"'))
  local fzf_cmd = string.format(
    "fzf --bind 'start:reload:%s' --ansi --layout=reverse --prompt='%s> ' --delimiter=: %s --preview 'bat --color=always --highlight-line {2} {1}' --preview-window='right:60%%:+{2}-/2' %s",
    rg_cmd, filetype, expect, preview_toggle)

  run_fzf(buf, win, fzf_cmd, output_file, origin_win)
end

function M.setup()
  vim.keymap.set('n', '<leader>ff', M.find_files, { desc = 'Find files' })
  vim.keymap.set('n', '<leader>fg', M.grep_content, { desc = 'Grep content' })
  vim.keymap.set('n', '<leader>fw', M.grep_word, { desc = 'Grep word under cursor' })
  vim.keymap.set('n', '<leader>ft', M.grep_filetype, { desc = 'Grep by file type' })
end

return M
