-- Oil.nvim file explorer configuration
local M = {}

function M.setup()
  -- Install oil.nvim
  local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/oil.nvim'
  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({'git', 'clone', '--depth', '1', 'https://github.com/stevearc/oil.nvim.git', install_path})
    vim.cmd('packadd oil.nvim')
  end

  require('oil').setup({
    -- Use default file icons (set to false if you don't have a nerd font)
    default_file_explorer = true,

    columns = {
      "icon",
      -- "permissions",
      -- "size",
      -- "mtime",
    },

    -- Window settings
    view_options = {
      show_hidden = true,  -- Show dotfiles
    },

    -- Keymaps in oil buffer
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = "actions.select",
      ["<C-v>"] = "actions.select_vsplit",
      ["<C-s>"] = "actions.select_split",
      ["<C-t>"] = "actions.select_tab",
      ["<C-p>"] = "actions.preview",
      ["<C-c>"] = "actions.close",
      ["<C-r>"] = "actions.refresh",
      ["-"] = "actions.parent",
      -- Disable default bindings that conflict with window navigation
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["_"] = "actions.open_cwd",
      ["`"] = "actions.cd",
      ["~"] = "actions.tcd",
      ["gs"] = "actions.change_sort",
      ["gx"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
      -- Copy path of file/dir under cursor to clipboard
      ["gy"] = {
        callback = function()
          local entry = require("oil").get_cursor_entry()
          local dir = require("oil").get_current_dir()
          if entry then
            local path = dir .. entry.name
            vim.fn.setreg("+", path)
            vim.notify("Copied: " .. path)
          end
        end,
        mode = "n",
        desc = "Copy entry path to clipboard",
      },
      -- Copy current directory path to clipboard
      ["gY"] = {
        callback = function()
          local dir = require("oil").get_current_dir()
          vim.fn.setreg("+", dir)
          vim.notify("Copied: " .. dir)
        end,
        mode = "n",
        desc = "Copy current directory to clipboard",
      },
    },

    -- Skip confirmation for simple operations
    skip_confirm_for_simple_edits = true,
  })

  -- Keybind to open oil
  vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory in Oil' })
end

return M
