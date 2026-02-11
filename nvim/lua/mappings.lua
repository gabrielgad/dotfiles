-- Centralized keybind mappings
local M = {}

-- Helper function for setting keymaps
local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- General keybinds
function M.setup_general()
  -- Disable unwanted default keybinds
  map('n', 'q', '<nop>', { desc = 'Disabled macro recording' })
  map('n', 'Q', '<nop>', { desc = 'Disabled Ex mode' })
  
  -- Exit insert mode with jk
  map('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })
  
  -- Clipboard operations
  map('n', '<leader>ya', 'ggVG"+y<C-o>', { desc = 'Yank entire file to clipboard' })

  -- Save operations
  map('n', '<leader>w', ':w<CR>', { desc = 'Save file' })
  map('n', '<leader>wa', function()
    local modified_buffers = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].modified then
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name ~= '' then
          table.insert(modified_buffers, vim.fn.fnamemodify(name, ':t'))
        end
      end
    end

    if #modified_buffers > 0 then
      vim.cmd('wa')
      print(string.format('Saved %d buffer%s: %s',
        #modified_buffers,
        #modified_buffers > 1 and 's' or '',
        table.concat(modified_buffers, ', ')))
    else
      print('No modified buffers to save')
    end
  end, { desc = 'Save all files' })

  -- Clear search highlighting
  map('n', '<leader>/', ':noh<CR>', { desc = 'Clear search highlight' })

  -- Reload current file
  map('n', '<leader>r', function()
    local filepath = vim.fn.expand('%:p')
    if filepath == '' then
      print('No file open to reload')
      return
    end

    local stat_before = vim.loop.fs_stat(filepath)
    if not stat_before then
      print('File does not exist: ' .. vim.fn.expand('%:t'))
      return
    end

    local modified = vim.bo.modified
    local lines_before = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content_before = table.concat(lines_before, '\n')

    vim.cmd('checktime')
    vim.cmd('e!')

    local lines_after = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content_after = table.concat(lines_after, '\n')

    if content_before == content_after then
      if modified then
        print('File reloaded (unsaved changes discarded)')
      else
        print('File reloaded (no changes detected)')
      end
    else
      print('File reloaded with external changes')
    end
  end, { desc = 'Reload current file' })

  -- Change working directory to current file/oil directory
  map('n', '<leader>cd', function()
    local dir
    local ok, oil = pcall(require, 'oil')
    if ok and oil.get_current_dir then
      dir = oil.get_current_dir()
    end
    if not dir then
      dir = vim.fn.expand('%:p:h')
    end
    if dir and dir ~= '' then
      vim.cmd('cd ' .. vim.fn.fnameescape(dir))
      print('cd ' .. dir)
    end
  end, { desc = 'Change directory to current file/oil dir' })
end

-- Buffer management keybinds
function M.setup_buffers()
  local bl = require('bufferline')

  -- Buffer navigation (window-scoped)
  map('n', '<leader>bn', bl.next_buf, { desc = 'Next buffer (window)' })
  map('n', '<leader>bp', bl.prev_buf, { desc = 'Previous buffer (window)' })
  map('n', '<leader>bd', bl.close_buf, { desc = 'Close buffer' })
  map('n', '<leader>bD', ':%bdelete!<CR>', { desc = 'Delete all buffers' })
  map('n', '<leader>bl', ':buffers<CR>', { desc = 'List buffers' })

  -- Quick buffer switching (window-scoped)
  map('n', '<Tab>', bl.next_buf, { desc = 'Next buffer (window)' })
  map('n', '<S-Tab>', bl.prev_buf, { desc = 'Previous buffer (window)' })
end

-- Window/split management keybinds
function M.setup_windows()
  -- Split creation
  map('n', '<leader>sv', ':vsplit<CR>', { desc = 'Split window vertically' })
  map('n', '<leader>sh', ':split<CR>', { desc = 'Split window horizontally' })
  map('n', '<leader>sc', ':close<CR>', { desc = 'Close current window' })
  map('n', '<leader>so', ':only<CR>', { desc = 'Close all other windows' })
  
  -- Window navigation (using Ctrl + hjkl)
  map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
  map('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
  map('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
  map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })
  
  -- Window resizing
  map('n', '<leader>+', ':resize +5<CR>', { desc = 'Increase window height' })
  map('n', '<leader>-', ':resize -5<CR>', { desc = 'Decrease window height' })
  map('n', '<leader>>', ':vertical resize +5<CR>', { desc = 'Increase window width' })
  map('n', '<leader><', ':vertical resize -5<CR>', { desc = 'Decrease window width' })
end

-- Auto-pairing keybinds for insert mode
function M.setup_autopairs()
  map('i', '(', '()<Left>', { desc = 'Auto-pair parentheses' })
  map('i', '[', '[]<Left>', { desc = 'Auto-pair square brackets' })
  map('i', '{', '{}<Left>', { desc = 'Auto-pair curly braces' })
  map('i', '"', '""<Left>', { desc = 'Auto-pair double quotes' })
  map('i', "'", "''<Left>", { desc = 'Auto-pair single quotes' })
end

-- LSP keybinds (to be called from LSP on_attach)
function M.setup_lsp(bufnr)
  local opts = { buffer = bufnr, silent = true }
  local fzf_lsp = require('fzf-lsp')
  
  -- Navigation
  map('n', 'gd', fzf_lsp.definitions, vim.tbl_extend('force', opts, { desc = 'Go to definition (fzf)' }))
  map('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'Go to declaration' }))
  map('n', 'gr', fzf_lsp.references, vim.tbl_extend('force', opts, { desc = 'Go to references (fzf)' }))
  map('n', 'gi', fzf_lsp.implementations, vim.tbl_extend('force', opts, { desc = 'Go to implementation (fzf)' }))
  map('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))
  map('n', '<leader>K', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = 'Signature help' }))
  
  -- Actions
  map('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
  map('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code action' }))
  map('n', '<leader>f', function()
    vim.lsp.buf.format({ async = true })
  end, vim.tbl_extend('force', opts, { desc = 'Format code' }))
  
  -- Diagnostics
  map('n', '[d', vim.diagnostic.goto_prev, vim.tbl_extend('force', opts, { desc = 'Previous diagnostic' }))
  map('n', ']d', vim.diagnostic.goto_next, vim.tbl_extend('force', opts, { desc = 'Next diagnostic' }))
  map('n', '<leader>d', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = 'Show diagnostic' }))

  -- Diagnostic lists - jump to pane or create if missing
  map('n', '<leader>q', function()
    local loclist_winid = vim.fn.getloclist(0, {winid = 0}).winid
    if loclist_winid ~= 0 then
      -- Location list exists, jump to it
      vim.api.nvim_set_current_win(loclist_winid)
    else
      -- Create location list and set up keymaps
      vim.diagnostic.setloclist()
      vim.schedule(function()
        local new_loclist_winid = vim.fn.getloclist(0, {winid = 0}).winid
        if new_loclist_winid ~= 0 then
          local loclist_bufnr = vim.fn.winbufnr(new_loclist_winid)
          if loclist_bufnr ~= -1 then
            vim.keymap.set('n', 'q', '<cmd>lclose<CR>', { buffer = loclist_bufnr, silent = true })
            vim.keymap.set('n', '<Esc>', '<cmd>lclose<CR>', { buffer = loclist_bufnr, silent = true })
            vim.keymap.set('n', 'r', function()
              vim.cmd('lclose')
              vim.schedule(function()
                vim.diagnostic.setloclist()
              end)
            end, { buffer = loclist_bufnr, silent = true, desc = 'Refresh diagnostics' })
          end
          vim.api.nvim_set_current_win(new_loclist_winid)
        end
      end)
    end
  end, vim.tbl_extend('force', opts, { desc = 'Jump to buffer diagnostics' }))

  map('n', '<leader>Q', function()
    local qflist_winid = vim.fn.getqflist({winid = 0}).winid
    if qflist_winid ~= 0 then
      -- Quickfix list exists, jump to it
      vim.api.nvim_set_current_win(qflist_winid)
    else
      -- No quickfix list, run build check
      vim.cmd('BuildCheck')
    end
  end, vim.tbl_extend('force', opts, { desc = 'Jump to build errors or run build check' }))
  
  
end

-- Tool/utility keybinds
function M.setup_tools()
  -- Document symbols
  map('n', '<leader>s', function() require('fzf-lsp').document_symbols() end, { desc = 'Document symbols (fzf)' })

  -- Keybind viewer (integrating existing functionality)
  map('n', '<leader>?', function() require('keybinds').toggle() end, { desc = 'Toggle keybind viewer' })
  map('n', '<leader>k', function() require('keybinds').toggle() end, { desc = 'Toggle keybind viewer' })

  -- Claude Code
  map('n', '<leader>ac', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })
  map('n', '<leader>af', '<cmd>ClaudeCodeFocus<CR>', { desc = 'Focus Claude Code' })
  map('v', '<leader>as', '<cmd>ClaudeCodeSend<CR>', { desc = 'Send selection to Claude' })
  map('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<CR>', { desc = 'Select Claude model' })
end

-- Main setup function
function M.setup()
  M.setup_general()
  M.setup_buffers()
  M.setup_windows()
  M.setup_autopairs()
  M.setup_tools()
end

return M