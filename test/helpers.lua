local M = {}

-- Replaces termcodes and feeds keys synchronously (including mapped keys)
function M.feedkeys(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "tx", false)
end

-- Opens a fresh buffer with the given lines and the 'text' filetype,
-- positions the cursor at the end of the last line, and returns the bufnr.
function M.new_buffer(lines)
  vim.cmd("enew")
  vim.bo.filetype = "text"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  local last = #lines
  vim.api.nvim_win_set_cursor(0, { last, #lines[last] })
  return vim.api.nvim_get_current_buf()
end

-- Returns all lines of the current buffer.
function M.get_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

-- Sets up a buffer with initial_lines, appends second_bullet via <CR>,
-- then asserts the buffer matches expected_lines.
function M.test_bullet_inserted(second_bullet, initial_lines, expected_lines)
  M.new_buffer(initial_lines)
  M.feedkeys("A<CR>" .. second_bullet)
  assert.are.same(expected_lines, M.get_lines())
end

-- Resets all bullets.vim globals to their plugin defaults.
-- Call in before_each for any describe block that mutates config.
function M.reset_config()
  vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit", "scratch" }
  vim.g.bullets_enable_in_empty_buffers = 1
  vim.g.bullets_set_mappings = 1
  vim.g.bullets_mapping_leader = ""
  vim.g.bullets_custom_mappings = {}
  vim.g.bullets_max_alpha_characters = 2
  vim.g.bullets_auto_indent_after_colon = 1
  vim.g.bullets_line_spacing = 1
  vim.g.bullets_renumber_on_change = 1
  vim.g.bullets_nested_checkboxes = 1
  vim.g.bullets_checkbox_markers = " .oOX"
  vim.g.bullets_checkbox_partials_toggle = 1
  vim.g.bullets_outline_levels = { "ROM", "ABC", "num", "abc", "rom", "std-", "std*", "std+" }
  vim.g.bullets_enable_roman_list = 1
  vim.g.bullets_pad_right = 1
  vim.g.bullets_delete_last_bullet_if_empty = 1
end

return M
