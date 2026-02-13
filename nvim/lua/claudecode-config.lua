-- Claude Code Integration (coder/claudecode.nvim)
local M = {}

function M.setup()
  require("claudecode").setup({
    terminal_cmd = "codeutil",
    log_level = "info",
    terminal = {
      provider = "external",
      provider_opts = {
        external_terminal_cmd = function(cmd_string, env_table)
          -- Write a temp nushell script with cd, env vars, and command
          local cwd = vim.fn.getcwd()
          local script_path = vim.fn.expand("$TEMP/claude-launch.nu")
          local f = io.open(script_path, "w")
          if f then
            f:write(string.format("cd '%s'\n", cwd))
            for k, v in pairs(env_table or {}) do
              f:write(string.format("$env.%s = '%s'\n", k, v))
            end
            f:write(cmd_string .. "\n")
            f:close()
          end
          return { "nu", "-c", string.format("^wt -w 0 nt nu %s", script_path) }
        end,
      },
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
