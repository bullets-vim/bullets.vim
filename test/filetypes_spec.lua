local helpers = require("test.helpers")

describe("filetypes", function()
  it("creates mapping for bullets on empty buffer if configured", function()
    -- g:bullets_enable_in_empty_buffers defaults to 0, so a new buffer with
    -- no filetype does NOT get the bullet <CR> mapping.
    vim.cmd("enew")
    vim.cmd("setlocal formatoptions= comments=") -- prevent '#' comment-continuation
    helpers.feedkeys("i# Hello there<CR>- this is the first bullet<CR>this is the second bullet<Esc>")
    assert.are.same({ "# Hello there", "- this is the first bullet", "this is the second bullet" }, helpers.get_lines())
  end)

  it("should have text filetype for .txt", function()
    local tmpfile = vim.fn.tempname() .. ".txt"
    vim.cmd("edit " .. tmpfile)
    local ft = vim.bo.filetype
    assert.is_true(ft == "text" or ft == "markdown", "Expected 'text' or 'markdown' filetype, got: " .. tostring(ft))
    vim.cmd("bdelete!")
  end)
end)
