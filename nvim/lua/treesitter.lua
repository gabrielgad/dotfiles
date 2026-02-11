-- Treesitter configuration for syntax highlighting
local M = {}

function M.setup()
  -- Install treesitter
  local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/nvim-treesitter'
  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({'git', 'clone', '--depth', '1', 'https://github.com/nvim-treesitter/nvim-treesitter.git', install_path})
    vim.cmd('packadd nvim-treesitter')
  end

  require('nvim-treesitter.configs').setup({
    ensure_installed = { "rust", "go", "typescript", "zig", "markdown", "markdown_inline" },
    sync_install = false,  -- Install parsers synchronously (only applied to `ensure_installed`)
    auto_install = true,   -- Automatically install missing parsers when entering buffer
    
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    
    -- Disable other features to keep it lightweight
    indent = { enable = false },
    incremental_selection = { enable = false },
    textobjects = { enable = false },
  })
end

return M