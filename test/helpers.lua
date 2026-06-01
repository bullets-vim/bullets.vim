local M = {}

-- Replaces termcodes and feeds keys synchronously (including mapped keys)
function M.feedkeys(keys)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, false, true),
    'tx',
    false
  )
end

-- Opens a fresh buffer with the given lines and the 'text' filetype,
-- positions the cursor at the end of the last line, and returns the bufnr.
function M.new_buffer(lines)
  vim.cmd('enew')
  vim.bo.filetype = 'text'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  local last = #lines
  vim.api.nvim_win_set_cursor(0, { last, #lines[last] })
  return vim.api.nvim_get_current_buf()
end

-- Mirrors the Ruby test_bullet_inserted helper:
-- sets up a buffer with initial_lines, appends second_bullet via <CR>,
-- then asserts the buffer matches expected_lines.
function M.test_bullet_inserted(second_bullet, initial_lines, expected_lines)
  M.new_buffer(initial_lines)
  M.feedkeys('A<CR>' .. second_bullet)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert.are.same(expected_lines, lines)
end

return M
