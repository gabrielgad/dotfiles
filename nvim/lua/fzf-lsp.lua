-- FZF integration for LSP functionality
local M = {}

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
local function format_lsp_item(item)
  local filename = vim.fn.fnamemodify(item.filename or item.uri:gsub("file://", ""), ":~:.")
  local line = item.lnum or item.range.start.line + 1
  local col = item.col or item.range.start.character + 1
  local text = item.text or ""
  
  -- Clean up the text (remove leading whitespace, limit length)
  text = text:gsub("^%s+", ""):gsub("%s+", " ")
  if #text > 60 then
    text = text:sub(1, 57) .. "..."
  end
  
  return string.format("%s:%d:%d: %s", filename, line, col, text)
end

-- Create fzf selection function
local function create_fzf_handler(items, title)
  return function()
    if not items or #items == 0 then
      print("No " .. (title or "items") .. " found")
      return
    end
    
    -- Format items for fzf
    local fzf_items = {}
    for i, item in ipairs(items) do
      table.insert(fzf_items, format_lsp_item(item))
    end
    
    -- Create temporary file with items
    local tmp_file = vim.fn.tempname()
    vim.fn.writefile(fzf_items, tmp_file)
    
    -- Create floating window for fzf
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    
    local win = vim.api.nvim_open_win(buf, true, {
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
    
    -- Disable line numbers for fzf
    vim.cmd('setlocal nonumber norelativenumber signcolumn=no')
    
    -- Create a temporary script to handle the selection
    local selection_file = vim.fn.tempname()
    local fzf_cmd = string.format(
      'fzf --ansi --prompt="%s> " --preview="echo {}" --preview-window=up:3:wrap --expect=ctrl-c,ctrl-g,ctrl-d,esc < %s > %s',
      title or "Select",
      tmp_file,
      selection_file
    )
    
    -- Add comprehensive escape key mappings for terminal mode
    vim.api.nvim_buf_set_keymap(buf, 't', '<Esc>', '<C-c>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-c>', '<C-c>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-d>', '<C-c>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-g>', '<C-c>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 't', 'q', '<C-c>', { noremap = true, silent = true })

    -- Add normal mode escape mappings for when terminal loses focus
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close!<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close!<CR>', { noremap = true, silent = true })

    -- Auto-close when leaving terminal mode (entering normal mode)
    vim.api.nvim_create_autocmd("TermLeave", {
      buffer = buf,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end,
      once = true
    })

    -- Start fzf
    vim.fn.termopen(fzf_cmd, {
      on_exit = function(_, exit_code)
        -- Clean up temp file
        vim.fn.delete(tmp_file)
        
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        
        if exit_code ~= 0 then
          vim.fn.delete(selection_file)
          return -- User cancelled
        end
        
        -- Read the selection from file
        if vim.fn.filereadable(selection_file) == 1 then
          local selected_lines = vim.fn.readfile(selection_file)
          if #selected_lines > 0 then
            -- Handle --expect output: first line is the key pressed, second line is the selection
            local key_pressed = selected_lines[1]
            local selected_line = selected_lines[2] or selected_lines[1]

            -- If an escape key was pressed, don't process the selection
            if key_pressed == "ctrl-c" or key_pressed == "ctrl-g" or key_pressed == "ctrl-d" or key_pressed == "esc" then
              return
            end

            -- If we have a valid selection, process it
            if selected_line and selected_line ~= "" then
              -- Parse the selection to find the corresponding item
              for i, formatted in ipairs(fzf_items) do
                if formatted == selected_line then
                  local item = items[i]
                  -- Jump to the selected location
                  local filename = item.filename or item.uri:gsub("file://", "")
                  local line = item.lnum or item.range.start.line + 1
                  local col = item.col or item.range.start.character + 1

                  -- Schedule the jump for after the terminal window closes
                  vim.schedule(function()
                    vim.cmd('edit ' .. vim.fn.fnameescape(filename))
                    vim.api.nvim_win_set_cursor(0, {line, col - 1})
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
    create_fzf_handler(items, "Document Symbols")()
  end)
end

return M