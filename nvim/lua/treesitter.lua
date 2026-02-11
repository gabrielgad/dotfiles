-- Treesitter configuration for syntax highlighting
local M = {}

function M.setup()
  require('nvim-treesitter').setup({
    ensure_installed = { "rust", "go", "typescript", "zig", "markdown", "markdown_inline", "lua", "bash" },
    auto_install = true,
  })
end

return M
