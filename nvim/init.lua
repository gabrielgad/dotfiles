-- Minimal Neovim configuration
vim.o.termguicolors = true

-- Enable syntax highlighting (defer some operations)
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- Set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set correct shell (use bash for terminal/fzf operations)
local bash_path = vim.fn.exepath('bash')
if bash_path ~= '' then
  vim.o.shell = bash_path
else
  vim.o.shell = 'bash'
end
vim.o.shellcmdflag = '-c'
if vim.fn.has('win32') == 1 then
  vim.o.shellquote = ''
  vim.o.shellxquote = ''
end

-- Clipboard integration
vim.opt.clipboard = 'unnamedplus'

-- Line numbers configuration
vim.opt.number = true
vim.opt.relativenumber = true

-- Buffer settings
vim.opt.hidden = true

-- Split direction
vim.opt.splitright = true
vim.opt.splitbelow = true

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

-- Claude Code integration
require('claudecode-config').setup()

-- Build error integration
require('build-errors').setup()

-- Oil file explorer
require('oil-config').setup()

-- Disable unused providers and features to reduce startup time
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

-- Performance optimizations
vim.opt.shadafile = "NONE"
vim.opt.swapfile = false

-- File change detection
vim.opt.autoread = true

-- Search settings
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Write cwd to temp file on exit (for shell wrapper to pick up)
vim.api.nvim_create_autocmd('VimLeave', {
  callback = function()
    local cwd_file = vim.fn.expand('$TEMP/nvim-cwd.txt')
    if not cwd_file or cwd_file == '' then
      cwd_file = vim.env.NVIM_CWD_FILE
    end
    if cwd_file and cwd_file ~= '' then
      local f = io.open(cwd_file, 'w')
      if f then
        f:write(vim.fn.getcwd())
        f:close()
      end
    end
  end
})
