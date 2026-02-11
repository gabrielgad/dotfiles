-- HTML Formatter for DevDocs and other HTML files
-- Converts HTML to clean, readable text with proper formatting

local M = {}

-- Clean and format HTML content
function M.format_html_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  -- Clean HTML tags and format content
  local formatted = M.clean_html(content)
  
  -- Split into lines and set buffer content
  local new_lines = vim.split(formatted, '\n')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
  
  -- Set filetype to markdown for better syntax highlighting
  vim.bo.filetype = 'markdown'
end

-- Main HTML cleaning function
function M.clean_html(html)
  local text = html
  
  -- Convert common HTML entities first
  text = text:gsub('&lt;', '<')
  text = text:gsub('&gt;', '>')
  text = text:gsub('&amp;', '&')
  text = text:gsub('&quot;', '"')
  text = text:gsub('&apos;', "'")
  text = text:gsub('&nbsp;', ' ')
  
  -- Convert code blocks to proper formatting
  text = text:gsub('<pre[^>]*>(.-)</pre>', function(code)
    -- Clean code content and add proper indentation
    local clean_code = code:gsub('<[^>]*>', '') -- Remove any remaining tags
    clean_code = clean_code:gsub('^%s+', ''):gsub('%s+$', '') -- Trim
    return '\n```\n' .. clean_code .. '\n```\n'
  end)
  
  -- Convert headings
  text = text:gsub('<h1[^>]*>(.-)</h1>', '\n# %1\n')
  text = text:gsub('<h2[^>]*>(.-)</h2>', '\n## %1\n')
  text = text:gsub('<h3[^>]*>(.-)</h3>', '\n### %1\n')
  text = text:gsub('<h4[^>]*>(.-)</h4>', '\n#### %1\n')
  
  -- Convert paragraphs (add line breaks)
  text = text:gsub('<p[^>]*>', '\n')
  text = text:gsub('</p>', '\n')
  
  -- Convert line breaks
  text = text:gsub('<br[^>]*/?>', '\n')
  
  -- Convert lists
  text = text:gsub('<ul[^>]*>', '\n')
  text = text:gsub('</ul>', '\n')
  text = text:gsub('<ol[^>]*>', '\n')
  text = text:gsub('</ol>', '\n')
  text = text:gsub('<li[^>]*>(.-)</li>', '• %1\n')
  
  -- Convert inline code
  text = text:gsub('<code[^>]*>(.-)</code>', '`%1`')
  
  -- Convert strong/bold
  text = text:gsub('<strong[^>]*>(.-)</strong>', '**%1**')
  text = text:gsub('<b[^>]*>(.-)</b>', '**%1**')
  
  -- Convert emphasis/italic
  text = text:gsub('<em[^>]*>(.-)</em>', '*%1*')
  text = text:gsub('<i[^>]*>(.-)</i>', '*%1*')
  
  -- Remove all remaining HTML tags
  text = text:gsub('<[^>]*>', '')
  
  -- Clean up whitespace
  text = text:gsub('\n%s*\n%s*\n', '\n\n') -- Multiple blank lines to double
  text = text:gsub('[ \t]+', ' ') -- Multiple spaces to single
  text = text:gsub(' *\n *', '\n') -- Spaces around newlines
  
  -- Wrap long lines (but preserve code blocks)
  text = M.wrap_text(text, 80)
  
  return text:gsub('^%s+', ''):gsub('%s+$', '') -- Final trim
end

-- Wrap text while preserving code blocks
function M.wrap_text(text, width)
  local lines = vim.split(text, '\n')
  local result = {}
  local in_code_block = false
  
  for _, line in ipairs(lines) do
    if line:match('^```') then
      in_code_block = not in_code_block
      table.insert(result, line)
    elseif in_code_block or line:match('^#') or line:match('^•') then
      -- Don't wrap code blocks, headers, or list items
      table.insert(result, line)
    elseif #line > width then
      -- Wrap long lines
      local wrapped = M.wrap_line(line, width)
      for _, wrapped_line in ipairs(wrapped) do
        table.insert(result, wrapped_line)
      end
    else
      table.insert(result, line)
    end
  end
  
  return table.concat(result, '\n')
end

-- Wrap a single line
function M.wrap_line(line, width)
  local words = vim.split(line, ' ')
  local lines = {}
  local current_line = ''
  
  for _, word in ipairs(words) do
    if #current_line + #word + 1 <= width then
      if current_line == '' then
        current_line = word
      else
        current_line = current_line .. ' ' .. word
      end
    else
      if current_line ~= '' then
        table.insert(lines, current_line)
      end
      current_line = word
    end
  end
  
  if current_line ~= '' then
    table.insert(lines, current_line)
  end
  
  return lines
end

-- Auto-format HTML files when opened
function M.setup()
  -- Create command to manually format HTML
  vim.api.nvim_create_user_command('FormatHTML', M.format_html_buffer, {
    desc = 'Format HTML file to readable text'
  })
  
  -- Auto-format HTML files when opened (optional)
  vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = '*.html',
    callback = function()
      -- Only auto-format if file is from devdocs
      local filepath = vim.fn.expand('%:p')
      if filepath:match('devdocs') then
        M.format_html_buffer()
      end
    end,
    desc = 'Auto-format DevDocs HTML files'
  })
end

return M