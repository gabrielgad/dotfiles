local M = {}

-- Find project root (look for package.json)
local function find_project_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir = vim.fn.fnamemodify(current_file, ':p:h')

  -- Walk up directories looking for package.json
  local path = current_dir
  while path ~= '/' do
    if vim.fn.filereadable(path .. '/package.json') == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ':h')
  end

  -- Fallback to current directory
  return vim.fn.getcwd()
end

-- Run build and lint for TypeScript files
local function run_typescript_checks()
  local filetype = vim.bo.filetype

  -- Only run for TypeScript/JavaScript files
  if not (filetype == 'typescript' or filetype == 'typescriptreact' or filetype == 'javascript' or filetype == 'javascriptreact') then
    vim.notify('Not a TypeScript/JavaScript file, skipping build checks', vim.log.levels.WARN)
    return
  end

  local project_root = find_project_root()
  vim.notify('Running yarn build and lint from: ' .. project_root, vim.log.levels.INFO)

  -- Change to project directory
  local original_cwd = vim.fn.getcwd()
  vim.cmd('cd ' .. vim.fn.fnameescape(project_root))

  -- Clear previous quickfix list
  vim.fn.setqflist({}, 'r')

  -- Set up error format for TypeScript/ESLint
  vim.opt.errorformat = {
    -- TypeScript formats
    '%f(%l\\,%c): %trror TS%n: %m',
    '%f:%l:%c - %trror TS%n: %m',
    '%f:%l:%c - %tarning TS%n: %m',
    '%f:%l:%c: %m',
    -- ESLint format: filename on one line, then indented errors
    '%f,%*[%^:]%l:%c  %t%*[^:]  %m',
    '%*[%^/]%f,%*[%^:]%l:%c  %t%*[^:]  %m',
    -- Alternative ESLint format
    '%A%f,%Z%*[%^:]%l:%c  %t%*[^:]  %m',
  }

  -- Run both commands and use caddexpr to add to quickfix
  vim.notify('Running yarn build and lint...', vim.log.levels.INFO)

  -- Filter function to ignore yarn/npm/lint noise
  local function should_include_line(line)
    if line == '' then return false end

    -- Skip yarn version but KEEP the command line ($ tsc --noEmit...)
    if line:match('^yarn run v') then return false end
    if line:match('^info Visit') then return false end
    if line:match('^error Command failed') then return false end
    if line:match('^Done in') then return false end

    -- Skip ESLint summary lines
    if line:match('^✖ %d+ problems') then return false end
    if line:match('errors and %d+ warnings potentially fixable') then return false end

    return true
  end

  -- Run yarn build, capture output, and add to quickfix
  local build_output = vim.fn.system('yarn build 2>&1')
  for _, line in ipairs(vim.split(build_output, '\n')) do
    if should_include_line(line) then
      vim.cmd('caddexpr ' .. vim.fn.string(line))
    end
  end

  -- Run yarn lint, capture output, and parse ESLint format
  local lint_output = vim.fn.system('yarn lint 2>&1')
  local current_file = nil

  for _, line in ipairs(vim.split(lint_output, '\n')) do
    if should_include_line(line) then
      -- Check if this is a file path line (starts with /)
      if line:match('^/.*%.ts$') or line:match('^/.*%.js$') or line:match('^/.*%.tsx$') or line:match('^/.*%.jsx$') then
        current_file = line
      -- Check if this is an ESLint error line (starts with spaces, then line:col)
      elseif current_file and line:match('^%s+(%d+):(%d+)%s+(%w+)%s+(.+)') then
        local lnum, col, severity, message = line:match('^%s+(%d+):(%d+)%s+(%w+)%s+(.+)')
        -- Convert to standard format: file:line:col: message
        local formatted_error = current_file .. ':' .. lnum .. ':' .. col .. ': ' .. message
        vim.cmd('caddexpr ' .. vim.fn.string(formatted_error))
      else
        -- For other lines (TypeScript errors), add as-is
        vim.cmd('caddexpr ' .. vim.fn.string(line))
      end
    end
  end

  -- Get final quickfix list
  local qflist = vim.fn.getqflist()


  -- Restore original directory
  vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))

  -- Open quickfix window if there are errors
  if #qflist > 0 then
    vim.cmd('copen')
    vim.notify(string.format('Found %d build/lint errors', #qflist), vim.log.levels.WARN)
  else
    vim.notify('No build or lint errors found!', vim.log.levels.INFO)
  end
end

-- Parse yarn/npm build output for better error format
local function setup_typescript_errorformat()
  -- TypeScript error format
  vim.opt.errorformat:append('%f(%l\\,%c): %trror TS%n: %m')
  vim.opt.errorformat:append('%f:%l:%c - %trror TS%n: %m')
  vim.opt.errorformat:append('%f:%l:%c - %tarning TS%n: %m')

  -- ESLint format
  vim.opt.errorformat:append('%f:%l:%c: %m')

  -- Generic format for other tools
  vim.opt.errorformat:append('%f:%l:%c: %t%*[^:]: %m')
end

-- Get all LSP diagnostics project-wide and put in quickfix
local function collect_all_lsp_diagnostics()
  local diagnostics = {}
  local buffers = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local buf_diagnostics = vim.diagnostic.get(bufnr)
      for _, diag in ipairs(buf_diagnostics) do
        local filename = vim.api.nvim_buf_get_name(bufnr)
        if filename ~= '' then
          table.insert(diagnostics, {
            filename = filename,
            lnum = diag.lnum + 1,
            col = diag.col + 1,
            text = diag.message,
            type = diag.severity == vim.diagnostic.severity.ERROR and 'E' or 'W'
          })
        end
      end
    end
  end

  -- Set quickfix list
  vim.fn.setqflist(diagnostics, 'r', { title = 'All LSP Diagnostics' })

  if #diagnostics > 0 then
    vim.cmd('copen')
    vim.notify(string.format('Found %d LSP diagnostics across project', #diagnostics), vim.log.levels.INFO)
  else
    vim.notify('No LSP diagnostics found!', vim.log.levels.INFO)
  end
end

-- Enhanced quickfix navigation
local function setup_quickfix_keybindings()
  -- Global quickfix navigation
  vim.keymap.set('n', ']q', ':cnext<CR>zz', { desc = 'Next quickfix item' })
  vim.keymap.set('n', '[q', ':cprev<CR>zz', { desc = 'Previous quickfix item' })
  vim.keymap.set('n', ']Q', ':clast<CR>zz', { desc = 'Last quickfix item' })
  vim.keymap.set('n', '[Q', ':cfirst<CR>zz', { desc = 'First quickfix item' })

  -- Quickfix window specific bindings
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function()
      local opts = { buffer = true, silent = true }
      vim.keymap.set('n', 'q', ':cclose<CR>', opts)
      vim.keymap.set('n', '<CR>', '<CR>zz', opts) -- Jump and center
      vim.keymap.set('n', 'r', function()
        vim.cmd('cclose')
        vim.schedule(function()
          vim.cmd('BuildCheck')
        end)
      end, vim.tbl_extend('force', opts, { desc = 'Rerun build check' }))
      vim.keymap.set('n', 'dd', function()
        local line = vim.fn.line('.')
        local qflist = vim.fn.getqflist()
        table.remove(qflist, line)
        vim.fn.setqflist(qflist, 'r')
        vim.cmd('cc')
      end, vim.tbl_extend('force', opts, { desc = 'Remove quickfix item' }))
    end
  })
end

function M.setup()
  setup_quickfix_keybindings()

  -- Main command - run build and lint for TS files
  vim.api.nvim_create_user_command('BuildCheck', run_typescript_checks,
    { desc = 'Run yarn build and lint for TypeScript files, show errors in quickfix' })

  -- LSP diagnostics collection
  vim.api.nvim_create_user_command('DiagnosticsAll', collect_all_lsp_diagnostics,
    { desc = 'Collect all LSP diagnostics project-wide' })
end

return M