-- Claude Code Integration (coder/claudecode.nvim)
local M = {}

function M.setup()
  require("claudecode").setup({
    terminal_cmd = "claude",
    log_level = "info",
    terminal = {
      split_side = "right",
      split_width_percentage = 0.4,
      provider = "native",
    },
    diff_opts = {
      layout = "vertical",
      open_in_new_tab = true,
      auto_close_on_accept = true,
    },
  })

  -- AI/Claude keybinds (leader+a prefix)
  vim.keymap.set("n", "<leader>aa", function()
    -- Get directory of current buffer, fallback to cwd
    local filepath = vim.fn.expand('%:p')
    local bufpath

    -- Handle Oil.nvim buffers (oil:///path/to/dir/)
    if filepath:match('^oil://') then
      local oil_path = filepath:gsub('^oil://', '')
      -- On Windows, oil uses /C/Users/... format, convert to C:/Users/...
      oil_path = oil_path:gsub('^/(%a)/', '%1:/')
      bufpath = oil_path:gsub('/$', '')
    else
      bufpath = vim.fn.expand('%:p:h')
    end

    if bufpath ~= '' and vim.fn.isdirectory(bufpath) == 1 then
      pcall(vim.api.nvim_set_current_dir, bufpath)
    end
    vim.cmd('ClaudeCode')
  end, { desc = "Toggle Claude Code in buffer's directory" })

  vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<CR>",
    { desc = "Send selection to Claude" })

  vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<CR>",
    { desc = "Focus Claude Code input" })

  vim.keymap.set("n", "<leader>ay", "<cmd>ClaudeCodeDiffAccept<CR>",
    { desc = "Accept Claude diff (yes)" })

  vim.keymap.set("n", "<leader>an", "<cmd>ClaudeCodeDiffDeny<CR>",
    { desc = "Deny Claude diff (no)" })
end

return M
