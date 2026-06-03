local function feedkeys(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "tx", false)
end

describe("Bullets.vim", function()
  it("loads the plugin", function()
    assert.equals(2, vim.fn.exists(":InsertNewBullet"))
  end)

  it("inserts a new bullet on <CR>", function()
    vim.cmd("enew")
    vim.bo.filetype = "text"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- first item" })
    vim.api.nvim_win_set_cursor(0, { 1, #"- first item" })

    feedkeys("A<CR>")

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.equals("- ", lines[2])
  end)
end)
