-- Minimal Neovim configuration
vim.o.termguicolors = true

-- Enable syntax highlighting (defer some operations)
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- Set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set shell to nushell if available, otherwise use system default
if vim.fn.executable('nu') == 1 then
  vim.o.shell = 'nu'
end

-- Clipboard integration
vim.opt.clipboard = 'unnamedplus'  -- Use system clipboard for all operations

-- Line numbers configuration
vim.opt.number = true
vim.opt.relativenumber = true

-- Buffer settings
vim.opt.hidden = true  -- Allow switching buffers without saving

-- Load the colorscheme (pcall so fresh installs without themix don't error)
local ok, theme = pcall(require, 'golden-lion')
if ok then
  theme.setup()
  vim.cmd('colorscheme golden-lion')
end

-- Terminal integration
require('terminal').setup()

-- Centralized keybind mappings
require('mappings').setup()

-- Keybind viewer
require('keybinds').setup()

-- Search functionality
require('search').setup()

-- Buffer line
require('bufferline').setup()

-- LSP configuration
require('lsp').setup()

-- Treesitter configuration
require('treesitter').setup()

-- Build error integration
require('build-errors').setup()

-- Claude Code integration
require('claudecode').setup({
  terminal = {
    provider = "native",
  },
})

-- Oil file explorer
require('oil').setup({
  columns = {
    "icon",
    "size",
    "mtime",
  },
  view_options = {
    show_hidden = true,
  },
  keymaps = {
    ["<C-p>"] = {
      "actions.preview",
      opts = { split = "belowright" },
    },
    ["<C-h>"] = false,
    ["<C-l>"] = false,
    ["<C-r>"] = "actions.refresh",
  },
})
-- Hide misleading directory sizes in oil
local files_adapter = require('oil.adapters.files')
local orig_get_column = files_adapter.get_column
files_adapter.get_column = function(name)
  local col = orig_get_column(name)
  if name == "size" and col then
    local orig_render = col.render
    col.render = function(entry, conf)
      if entry[require('oil.constants').FIELD_TYPE] == "directory" then
        return ""
      end
      return orig_render(entry, conf)
    end
  end
  return col
end
vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory (Oil)' })

-- Disable unused providers and features to reduce startup time
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0  -- We installed it but don't need it for basic usage
vim.g.loaded_python3_provider = 0  -- Disable if not using Python plugins

-- Write cwd to temp file on exit (used by shell wrapper to cd after nvim)
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    local cwd_file = vim.env.NVIM_CWD_FILE
    if cwd_file then
      vim.fn.writefile({vim.fn.getcwd()}, cwd_file)
    end
  end,
})

-- File change detection
vim.opt.autoread = true  -- Automatically reload files changed outside vim
