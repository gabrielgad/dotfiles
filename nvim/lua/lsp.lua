-- LSP configuration for multiple languages
local M = {}

-- LSP setup function
function M.setup()
  vim.lsp.set_log_level("warn")
  
  -- Enable basic completion
  vim.opt.completeopt = {'menu', 'menuone', 'noselect'}
  
  -- LSP key mappings
  local function on_attach(client, bufnr)
    -- Use centralized LSP keybinds
    require('mappings').setup_lsp(bufnr)
  end

  -- Enhanced capabilities for autocompletion
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  
  -- LSP configurations (only start when needed)
  local lsp_configs = {
    go = {
      name = 'gopls',
      cmd = {'gopls'},
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
      cmd = {'rust-analyzer'},
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
      cmd = {'zls'},
      filetypes = {'zig'},
      root_patterns = {'build.zig', '.git'},
    },
    c = {
      name = 'clangd',
      cmd = {'clangd'},
      filetypes = {'c', 'cpp', 'objc', 'objcpp'},
      root_patterns = {'compile_commands.json', 'compile_flags.txt', '.clangd', '.git'},
    },
    typescript = {
      name = 'typescript-language-server',
      cmd = {'typescript-language-server', '--stdio'},
      filetypes = {'javascript', 'javascriptreact', 'typescript', 'typescriptreact'},
      root_patterns = {'tsconfig.json', 'package.json', 'jsconfig.json', '.git'},
    },
    fsharp = {
      name = 'fsautocomplete',
      cmd = {'fsautocomplete', '--background-service-enabled'},
      filetypes = {'fsharp'},
      root_patterns = {'*.sln', '*.fsproj', '.git'},
    },
    csharp = {
      name = 'omnisharp',
      cmd = {'omnisharp', '-lsp'},
      filetypes = {'cs'},
      root_patterns = {'*.sln', '*.csproj', '.git'},
    },
    html = {
      name = 'html-lsp',
      cmd = {'vscode-html-language-server', '--stdio'},
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

    -- Find root directory
    local found = vim.fs.find(config.root_patterns, { upward = true })[1]
    if not found then return end
    local root_dir = vim.fs.dirname(found)

    -- Start LSP
    vim.lsp.start({
      name = config.name,
      cmd = config.cmd,
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