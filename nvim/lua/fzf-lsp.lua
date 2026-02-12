-- FZF integration for LSP functionality
local M = {}

-- Normalize paths for bash (backslashes → forward slashes)
local function bp(path)
  return path:gsub('\\', '/')
end

-- Retry-aware LSP request wrapper (handles ContentModified)
local function lsp_request(method, params, callback, retries)
  retries = retries or 3
  vim.lsp.buf_request(0, method, params, function(err, result, ctx)
    if err and err.code == -32801 and retries > 0 then
      vim.defer_fn(function()
        lsp_request(method, params, callback, retries - 1)
      end, 200)
      return
    end
    callback(err, result, ctx)
  end)
end

-- Jump to a single LSP location directly
local function jump_to_location(loc)
  local uri = loc.uri or loc.targetUri
  local range = loc.range or loc.targetRange
  local filename = vim.uri_to_fname(uri)
  vim.cmd('edit ' .. vim.fn.fnameescape(filename))
  vim.api.nvim_win_set_cursor(0, {range.start.line + 1, range.start.character})
  vim.cmd('normal! zz')
end

-- Helper function to format LSP locations for fzf
local function format_lsp_item(item, compact)
  local filename = item.filename or vim.uri_to_fname(item.uri)
  local line = item.lnum or item.range.start.line + 1
  local col = item.col or item.range.start.character + 1
  local text = item.text or ""

  -- Clean up the text (remove leading whitespace, limit length)
  text = text:gsub("^%s+", ""):gsub("%s+", " ")
  if #text > 60 then
    text = text:sub(1, 57) .. "..."
  end

  if compact then
    -- Show just the filename (no directories) for document symbols
    local short = vim.fn.fnamemodify(filename, ":t")
    return string.format("%s:%d:%d: %s", short, line, col, text)
  end

  return string.format("%s:%d:%d: %s", filename, line, col, text)
end

-- Create fzf selection function
local function create_fzf_handler(items, title, compact)
  return function()
    if not items or #items == 0 then
      print("No " .. (title or "items") .. " found")
      return
    end

    -- Format items for fzf
    local fzf_items = {}
    for _, item in ipairs(items) do
      table.insert(fzf_items, format_lsp_item(item, compact))
    end

    -- Create temporary file with items
    local tmp_file = vim.fn.tempname()
    vim.fn.writefile(fzf_items, tmp_file)

    -- Create floating window for fzf
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local ok_buf, buf = pcall(vim.api.nvim_create_buf, false, true)
    if not ok_buf then return end
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    local ok_win, win = pcall(vim.api.nvim_open_win, buf, true, {
      relative = 'editor',
      width = width,
      height = height,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
      title = ' ' .. (title or "LSP Items") .. ' ',
      title_pos = 'center'
    })
    if not ok_win then return end

    vim.cmd('setlocal nonumber norelativenumber signcolumn=no')

    local selection_file = vim.fn.tempname()

    -- Build preview command inline (no bash scripts needed)
    local preview_cmd
    if compact then
      -- Document symbols: all in same file, use full path directly
      local full_path = items[1] and items[1].filename or ""
      preview_cmd = string.format(
        [[bat --color=always --style=numbers --highlight-line {2} '%s']],
        bp(full_path))
    else
      -- References/definitions: {1} is filename, {2} is line number
      preview_cmd = [[bat --color=always --style=numbers --highlight-line {2} {1}]]
    end

    -- Build fzf command as a string (no script files)
    -- SHELL=nu makes fzf use nushell for preview (faster than MSYS2 bash)
    local fzf_cmd = string.format(
      [[SHELL=nu fzf --ansi --prompt="%s> " --delimiter=: --preview '%s' --preview-window='right:60%%:+{2}-/2' --layout=reverse --expect=ctrl-c,ctrl-g,ctrl-d --bind 'ctrl-/:toggle-preview' < '%s' > '%s']],
      title or "Select", preview_cmd, bp(tmp_file), bp(selection_file))

    -- Normal mode close
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close!<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close!<CR>', { noremap = true, silent = true })

    -- Override global terminal-mode window-nav mappings so they pass through to fzf
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-j>', '<C-j>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-k>', '<C-k>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-h>', '<C-h>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-l>', '<C-l>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-n>', '<C-n>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-p>', '<C-p>', { noremap = true, silent = true })

    -- Start fzf (use vim.o.shell to avoid WSL bash)
    local ok_term, _ = pcall(vim.fn.termopen, {vim.o.shell, '-c', fzf_cmd}, {
      on_exit = function(_, exit_code)
        vim.fn.delete(tmp_file)

        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end

        if exit_code ~= 0 then
          vim.fn.delete(selection_file)
          return
        end

        if vim.fn.filereadable(selection_file) == 1 then
          local selected_lines = vim.fn.readfile(selection_file)
          if #selected_lines > 0 then
            local key_pressed = selected_lines[1]
            local selected_line = selected_lines[2] or selected_lines[1]

            if key_pressed == "ctrl-c" or key_pressed == "ctrl-g" or key_pressed == "ctrl-d" or key_pressed == "esc" then
              return
            end

            if selected_line and selected_line ~= "" then
              for i, formatted in ipairs(fzf_items) do
                if formatted == selected_line then
                  local item = items[i]
                  local filename = item.filename or vim.uri_to_fname(item.uri)
                  local lnum = item.lnum or item.range.start.line + 1
                  local col_num = item.col or item.range.start.character + 1

                  vim.schedule(function()
                    vim.cmd('edit ' .. vim.fn.fnameescape(filename))
                    vim.api.nvim_win_set_cursor(0, {lnum, col_num - 1})
                    vim.cmd('normal! zz')
                  end)
                  break
                end
              end
            end
          end
        end

        vim.fn.delete(selection_file)
      end
    })
    if not ok_term then
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      return
    end

    vim.cmd('startinsert')
  end
end

-- LSP references with fzf
function M.references()
  local params = vim.lsp.util.make_position_params(0, 'utf-8')
  params.context = { includeDeclaration = true }

  lsp_request('textDocument/references', params, function(err, result)
    if err then
      print("LSP references error: " .. (err.message or tostring(err)))
      return
    end

    if not result or #result == 0 then
      print("No references found")
      return
    end

    if #result == 1 then
      jump_to_location(result[1])
      return
    end

    local items = {}
    for _, ref in ipairs(result) do
      local filename = vim.uri_to_fname(ref.uri)
      local bufnr = vim.fn.bufnr(filename)
      local text = ""

      if bufnr ~= -1 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, ref.range.start.line, ref.range.start.line + 1, false)
        if lines and lines[1] then
          text = lines[1]
        end
      end

      table.insert(items, {
        filename = filename,
        range = ref.range,
        text = text
      })
    end

    create_fzf_handler(items, "References")()
  end)
end

-- LSP definitions with fzf
function M.definitions()
  local params = vim.lsp.util.make_position_params(0, 'utf-8')

  lsp_request('textDocument/definition', params, function(err, result)
    if err then
      print("LSP definition error: " .. (err.message or tostring(err)))
      return
    end

    if not result or #result == 0 then
      print("No definitions found")
      return
    end

    -- Handle single definition
    if #result == 1 then
      local location = result[1]
      local uri = location.uri or location.targetUri
      local range = location.range or location.targetRange

      -- Open the file and jump to location
      local filename = vim.uri_to_fname(uri)
      vim.cmd('edit ' .. vim.fn.fnameescape(filename))
      local line = range.start.line + 1
      local col = range.start.character
      vim.api.nvim_win_set_cursor(0, {line, col})
      vim.cmd('normal! zz')
      return
    end

    -- Multiple definitions - use fzf
    local items = {}
    for _, def in ipairs(result) do
      local filename = vim.uri_to_fname(def.uri)
      local bufnr = vim.fn.bufnr(filename)
      local text = ""

      if bufnr ~= -1 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, def.range.start.line, def.range.start.line + 1, false)
        if lines and lines[1] then
          text = lines[1]
        end
      end

      table.insert(items, {
        filename = filename,
        range = def.range,
        text = text
      })
    end

    create_fzf_handler(items, "Definitions")()
  end)
end

-- LSP implementations with fzf
function M.implementations()
  local params = vim.lsp.util.make_position_params(0, 'utf-8')

  lsp_request('textDocument/implementation', params, function(err, result)
    if err then
      print("LSP implementation error: " .. (err.message or tostring(err)))
      return
    end

    if not result or #result == 0 then
      print("No implementations found")
      return
    end

    if #result == 1 then
      jump_to_location(result[1])
      return
    end

    local items = {}
    for _, impl in ipairs(result) do
      local filename = vim.uri_to_fname(impl.uri)
      local bufnr = vim.fn.bufnr(filename)
      local text = ""

      if bufnr ~= -1 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, impl.range.start.line, impl.range.start.line + 1, false)
        if lines and lines[1] then
          text = lines[1]
        end
      end

      table.insert(items, {
        filename = filename,
        range = impl.range,
        text = text
      })
    end

    create_fzf_handler(items, "Implementations")()
  end)
end

-- LSP document symbols with fzf
function M.document_symbols()
  local params = vim.lsp.util.make_position_params(0, 'utf-8')
  params.textDocument = vim.lsp.util.make_text_document_params(0, 'utf-8')

  lsp_request('textDocument/documentSymbol', params, function(err, result)
    if err then
      print("LSP symbols error: " .. (err.message or tostring(err)))
      return
    end

    if not result or #result == 0 then
      print("No symbols found")
      return
    end

    local items = {}
    local function process_symbols(symbols, prefix)
      prefix = prefix or ""

      for _, symbol in ipairs(symbols) do
        local name = prefix .. symbol.name
        local kind = vim.lsp.protocol.SymbolKind[symbol.kind] or "Unknown"
        local range = symbol.selectionRange or symbol.range

        table.insert(items, {
          filename = vim.api.nvim_buf_get_name(0),
          range = range,
          text = string.format("[%s] %s", kind, name)
        })

        -- Process nested symbols
        if symbol.children then
          process_symbols(symbol.children, name .. ".")
        end
      end
    end

    process_symbols(result)
    create_fzf_handler(items, "Document Symbols", true)()
  end)
end

return M
