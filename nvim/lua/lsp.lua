-- LSP configuration for multiple languages
local M = {}

-- Memory limit per LSP server (in bytes). Enforced via systemd cgroups.
-- Servers that exceed this are killed by the kernel, and nvim will auto-restart
-- them on the next request — effectively a periodic leak reset.
local LSP_MEMORY_MAX = '4G'

-- Wrap an LSP cmd table with systemd-run memory capping (Linux only)
local function capped_cmd(cmd)
  if vim.fn.has('win32') == 1 or vim.fn.executable('systemd-run') ~= 1 then
    return cmd
  end
  local capped = {'systemd-run', '--user', '--scope', '-p', 'MemoryMax=' .. LSP_MEMORY_MAX, '--'}
  for _, arg in ipairs(cmd) do
    table.insert(capped, arg)
  end
  return capped
end

-- LSP setup function
function M.setup()
  vim.lsp.set_log_level("warn")

  -- Enable basic completion
  vim.opt.completeopt = {'menu', 'menuone', 'noselect'}

  -- LSP key mappings
  local function on_attach(client, bufnr)
    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    require('mappings').setup_lsp(bufnr)
  end

  -- Enhanced capabilities for autocompletion
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- LSP configurations (only start when needed)
  local lsp_configs = {
    go = {
      name = 'gopls',
      cmd = capped_cmd({'gopls'}),
      filetypes = {'go', 'gomod', 'gowork', 'gotmpl'},
      root_patterns = {'go.work', 'go.mod', '.git'},
      settings = {
        gopls = {
          completeUnimported = true,
          usePlaceholders = true,
          analyses = {
            unusedparams = true,
          },
        },
      },
    },
    rust = {
      name = 'rust_analyzer',
      cmd = capped_cmd({'rust-analyzer'}),
      filetypes = {'rust'},
      root_patterns = {'Cargo.toml', '.git'},
      settings = {
        ["rust-analyzer"] = {
          cargo = {
            allFeatures = true,
          },
          procMacro = {
            enable = true
          },
        },
      },
    },
    zig = {
      name = 'zls',
      cmd = capped_cmd({'zls'}),
      filetypes = {'zig'},
      root_patterns = {'build.zig', '.git'},
    },
    c = {
      name = 'clangd',
      cmd = capped_cmd({'clangd'}),
      filetypes = {'c', 'cpp', 'objc', 'objcpp'},
      root_patterns = {'compile_commands.json', 'compile_flags.txt', '.clangd', '.git'},
    },
    typescript = {
      name = 'typescript-language-server',
      cmd = capped_cmd({'typescript-language-server', '--stdio'}),
      filetypes = {'javascript', 'javascriptreact', 'typescript', 'typescriptreact'},
      root_patterns = {'tsconfig.json', 'package.json', 'jsconfig.json', '.git'},
    },
    fsharp = {
      name = 'fsautocomplete',
      cmd = capped_cmd({'fsautocomplete', '--background-service-enabled'}),
      filetypes = {'fsharp'},
      root_patterns = {'*.sln', '*.fsproj', '.git'},
    },
    csharp = {
      name = 'omnisharp',
      cmd = capped_cmd({'omnisharp', '-lsp'}),
      filetypes = {'cs'},
      root_patterns = {'*.sln', '*.csproj', '.git'},
    },
    lua = {
      name = 'lua_ls',
      cmd = capped_cmd({'lua-language-server'}),
      filetypes = {'lua'},
      root_patterns = {'.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', '.git'},
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME },
          },
          telemetry = { enable = false },
        },
      },
    },
    html = {
      name = 'html-lsp',
      cmd = capped_cmd({'vscode-html-language-server', '--stdio'}),
      filetypes = {'html'},
      root_patterns = {'package.json', '.git'},
      settings = {
        html = {
          format = {
            enable = true,
          },
          hover = {
            documentation = true,
            references = true,
          },
        },
      },
    },
  }
  
  -- Function to start LSP for specific filetype
  local function start_lsp_for_filetype(filetype)
    -- Find matching config
    local config = nil
    for _, lsp_config in pairs(lsp_configs) do
      for _, ft in ipairs(lsp_config.filetypes) do
        if ft == filetype then
          config = lsp_config
          break
        end
      end
      if config then break end
    end

    if not config then return end

    local cmd = vim.deepcopy(config.cmd)

    -- The actual LSP binary is after the systemd-run wrapper args
    local lsp_bin_idx = 1
    if cmd[1] == 'systemd-run' then
      for i, arg in ipairs(cmd) do
        if arg == '--' then lsp_bin_idx = i + 1; break end
      end
    end

    -- On Windows, npm-installed servers are POSIX shell scripts that native nvim can't spawn.
    if vim.fn.has('win32') == 1 and vim.fn.executable(cmd[lsp_bin_idx] .. '.cmd') == 1 then
      cmd[lsp_bin_idx] = cmd[lsp_bin_idx] .. '.cmd'
    end

    -- Check if the LSP binary exists
    if vim.fn.executable(cmd[lsp_bin_idx]) ~= 1 then
      return
    end

    -- Find root directory using a function matcher to support glob patterns
    local found = vim.fs.find(function(name)
      for _, pattern in ipairs(config.root_patterns) do
        if pattern:find('%*') then
          -- Glob pattern: convert to Lua pattern
          local lua_pattern = '^' .. pattern:gsub('%.', '%%.'):gsub('%*', '.*') .. '$'
          if name:match(lua_pattern) then return true end
        else
          if name == pattern then return true end
        end
      end
      return false
    end, { upward = true })

    local root_dir = found[1] and vim.fs.dirname(found[1]) or nil
    if not root_dir then return end

    -- Start LSP (vim.lsp.start reuses existing client for same name+root_dir)
    vim.lsp.start({
      name = config.name,
      cmd = cmd,
      filetypes = config.filetypes,
      root_dir = root_dir,
      on_attach = on_attach,
      capabilities = capabilities,
      settings = config.settings or {},
    })
  end
  
  -- Auto-start LSP when opening files
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      start_lsp_for_filetype(args.match)
    end,
  })

  -- Configure diagnostics display with signs
  local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
  vim.diagnostic.config({
    virtual_text = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = signs.Error,
        [vim.diagnostic.severity.WARN] = signs.Warn,
        [vim.diagnostic.severity.HINT] = signs.Hint,
        [vim.diagnostic.severity.INFO] = signs.Info,
      }
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  })
end

return M