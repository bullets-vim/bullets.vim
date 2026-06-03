local helpers = require("test.helpers")

describe("Bullets.vim", function()
  describe("nested bullets", function()
    before_each(function()
      helpers.reset_config()
      -- Plugin uses `normal! >>` / `normal! <<` internally which respect shiftwidth/expandtab.
      -- Set noexpandtab + shiftwidth=tabstop=4 so one indent level = one tab character.
      vim.opt.expandtab = false
      vim.opt.shiftwidth = 4
      vim.opt.tabstop = 4
    end)

    it("demotes an existing bullet", function()
      helpers.new_buffer({
        "# Hello there",
        "I. this is the first bullet",
        "II. second bullet",
        "III. third bullet",
        "IV. fourth bullet",
        "V. fifth bullet",
        "VI. sixth bullet",
        "VII. seventh bullet",
        "VIII. eighth bullet",
        "IX. ninth bullet",
      })
      -- Go to line 3 (gg + 2j), enter insert, demote with <C-t>
      helpers.feedkeys("gg2ji<C-t>")
      -- Back to normal mode, go down 1 line, demote 3 times with >>
      helpers.feedkeys("j>>>>>>")
      -- Continue demoting subsequent lines
      helpers.feedkeys("j>>>>>>>>")
      helpers.feedkeys("j>>>>>>>>>>")
      helpers.feedkeys("j>>>>>>>>")
      helpers.feedkeys(">>>>")
      helpers.feedkeys("j>>>>>>>>")
      helpers.feedkeys(">>>>>>")
      helpers.feedkeys("j>>>>>>>>")
      helpers.feedkeys(">>>>>>>>")
      helpers.feedkeys("j>>>>>>>>")
      helpers.feedkeys(">>>>>>>>>>")
      assert.are.same({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
        "\t\t\t1. third bullet",
        "\t\t\t\ta. fourth bullet",
        "\t\t\t\t\ti. fifth bullet",
        "\t\t\t\t\t\t- sixth bullet",
        "\t\t\t\t\t\t\t* seventh bullet",
        "\t\t\t\t\t\t\t\t+ eighth bullet",
        "\t\t\t\t\t\t\t\t\t+ ninth bullet",
      }, helpers.get_lines())
    end)

    it("promotes an existing bullet", function()
      helpers.new_buffer({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
        "\t\t\t1. third bullet",
        "\t\t\t\ta. fourth bullet",
        "\t\t\t\t\ti. fifth bullet",
        "\t\t\t\t\t\t- sixth bullet",
        "\t\t\t\t\t\t\t* seventh bullet",
        "\t\t\t\t\t\t\t\t+ eighth bullet",
      })
      -- Go to line 3 (gg + 2j), promote with <<
      helpers.feedkeys("gg2j<<")
      -- Go to line 4, enter insert, demote twice with <C-d>
      helpers.feedkeys("ji<C-d><C-d>")
      -- Continue promoting subsequent lines
      helpers.feedkeys("j<<<<<<")
      helpers.feedkeys("j<<<<<<")
      helpers.feedkeys("<<<<")
      helpers.feedkeys("j<<<<<<")
      helpers.feedkeys("<<<<<<")
      helpers.feedkeys("j<<<<<<")
      helpers.feedkeys("<<<<<<<<")
      helpers.feedkeys("j<<<<<<")
      helpers.feedkeys("<<<<<<")
      helpers.feedkeys("<<<<")
      assert.are.same({
        "# Hello there",
        "I. this is the first bullet",
        "II. second bullet",
        "\tA. third bullet",
        "\tB. fourth bullet",
        "III. fifth bullet",
        "IV.  sixth bullet",
        "V.   seventh bullet",
        "VI.  eighth bullet",
      }, helpers.get_lines())
    end)

    it("demotes an empty bullet", function()
      helpers.new_buffer({
        "# Hello there",
        "I. this is the first bullet",
      })
      -- Enter insert at end, press CR (on bullet line), demote with <C-t>, type
      helpers.feedkeys("GA<CR><C-t>second bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
      }, helpers.get_lines())
    end)

    it("promotes an empty bullet", function()
      helpers.new_buffer({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
      })
      -- Enter insert at end, press CR (on bullet line), promote with <C-d>, type
      helpers.feedkeys("GA<CR><C-d>third bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
        "II. third bullet",
      }, helpers.get_lines())
    end)

    it("restarts numbering with multiple outlines", function()
      helpers.new_buffer({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
      })
      -- GA enters insert at end, <CR> on bullet line creates new bullet, then
      -- <CR> again on bullet line (empty), which should delete the empty bullet
      -- (delete_last_bullet_if_empty), leaving normal mode. Then another <CR> does
      -- the same. Then we type a new bullet manually.
      helpers.feedkeys("GA<CR>")
      -- Now on a new empty bullet line. CR again triggers delete-last-bullet
      helpers.feedkeys("A<CR>")
      -- Again on empty line
      helpers.feedkeys("A<CR>")
      -- Now type the manual bullet header
      helpers.feedkeys("iA. first bullet<Esc>")
      -- Enter insert at end, CR on bullet line, demote, type
      helpers.feedkeys("A<CR><C-t>second bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
        "",
        "A. first bullet",
        "\t1. second bullet",
      }, helpers.get_lines())
    end)

    it("works with custom outline level definitions", function()
      vim.g.bullets_outline_levels = { "num", "ABC", "std*" }
      helpers.new_buffer({
        "# Hello there",
      })
      -- Enter insert at end, CR (non-bullet line header, deferred CR)
      helpers.feedkeys("GA<CR>")
      -- Now in normal mode on new empty line - type the first bullet
      helpers.feedkeys("i1. first bullet<Esc>")
      -- CR on bullet line - stays in insert after plugin fires
      helpers.feedkeys("A<CR>second bullet<Esc>")
      -- CR on bullet line, then demote, then type
      helpers.feedkeys("A<CR><C-t>third bullet<Esc>")
      helpers.feedkeys("A<CR>fourth bullet<Esc>")
      helpers.feedkeys("A<CR><C-t>fifth bullet<Esc>")
      helpers.feedkeys("A<CR>sixth bullet<Esc>")
      helpers.feedkeys("A<CR><C-t>seventh bullet<Esc>")
      helpers.feedkeys("A<CR>eighth bullet<Esc>")
      -- demote twice, then type
      helpers.feedkeys("A<CR><C-d><C-d>ninth bullet<Esc>")
      -- demote once, then type
      helpers.feedkeys("A<CR><C-d>tenth bullet<Esc>")
      helpers.feedkeys("A<CR>eleventh bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "1. first bullet",
        "2. second bullet",
        "\tA. third bullet",
        "\tB. fourth bullet",
        "\t\t* fifth bullet",
        "\t\t* sixth bullet",
        "\t\t\t* seventh bullet",
        "\t\t\t* eighth bullet",
        "\tC. ninth bullet",
        "3. tenth bullet",
        "4. eleventh bullet",
      }, helpers.get_lines())
    end)

    it("promotes and demotes from different starting levels", function()
      helpers.new_buffer({
        "# Hello there",
        "1. this is the first bullet",
        "\ta. second bullet",
      })
      -- In insert mode at end, promote with <C-d> (still in insert after plugin's <C-o>:BulletPromote)
      helpers.feedkeys("GA<C-d>")
      -- Now "2. second bullet" in normal mode - CR on bullet line, demote, type
      helpers.feedkeys("A<CR><C-t>third bullet<Esc>")
      -- Two CRs: first creates empty \tb. bullet, second deletes it (delete_last_bullet_if_empty)
      helpers.feedkeys("A<CR>")
      helpers.feedkeys("A<CR>")
      -- Type the non-bullet manually on the blank line
      helpers.feedkeys("i+ fourth bullet<Esc>")
      -- CR on + bullet line, demote, type
      helpers.feedkeys("A<CR><C-t>fifth bullet<Esc>")
      -- Two CRs: first creates empty \t+ bullet, second deletes it
      helpers.feedkeys("A<CR>")
      helpers.feedkeys("A<CR>")
      -- Type the non-bullet manually
      helpers.feedkeys("i* sixth bullet<Esc>")
      -- CR on * bullet line creates * seventh bullet, type it
      helpers.feedkeys("A<CR>seventh bullet<Esc>")
      -- Re-enter insert at end and demote with <C-t>.
      helpers.feedkeys("A<C-t><Esc>")
      assert.are.same({
        "# Hello there",
        "1. this is the first bullet",
        "2. second bullet",
        "\ta. third bullet",
        "+ fourth bullet",
        "\t+ fifth bullet",
        "* sixth bullet",
        "\t+ seventh bullet",
      }, helpers.get_lines())
    end)

    it("does not nest beyond defined levels", function()
      helpers.new_buffer({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
        "\t\t1. third bullet",
        "\t\t\ta. fourth bullet",
        "\t\t\t\ti. fifth bullet",
        "\t\t\t\tii. sixth bullet",
        "\t\t\t\t\t- seventh bullet",
        "\t\t\t\t\t\t* eighth bullet",
        "\t\t\t\t\t\t\t+ ninth bullet",
      })
      -- GA enters insert at end, CR on bullet line, demote with <C-t>, type
      helpers.feedkeys("GA<CR><C-t>tenth bullet<Esc>")
      helpers.feedkeys("A<CR>eleventh bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
        "\t\t1. third bullet",
        "\t\t\ta. fourth bullet",
        "\t\t\t\ti. fifth bullet",
        "\t\t\t\tii. sixth bullet",
        "\t\t\t\t\t- seventh bullet",
        "\t\t\t\t\t\t* eighth bullet",
        "\t\t\t\t\t\t\t+ ninth bullet",
        "\t\t\t\t\t\t\t\t+ tenth bullet",
        "\t\t\t\t\t\t\t\t+ eleventh bullet",
      }, helpers.get_lines())
    end)

    it("removes bullet when promoting top level bullet", function()
      helpers.new_buffer({
        "# Hello there",
        "A. this is the first bullet",
        "",
        "I. second bullet",
        "\tA. third bullet",
      })
      -- Go to line 2 (gg + j), promote with <<
      helpers.feedkeys("ggj<<")
      -- Go to line 5 (3j from line 2 = line 5), enter insert, promote twice
      helpers.feedkeys("3ji<C-d><C-d>")
      assert.are.same({
        "# Hello there",
        "this is the first bullet",
        "",
        "I. second bullet",
        "third bullet",
      }, helpers.get_lines())
    end)

    it("handle standard bullets when they are not in outline list", function()
      vim.g.bullets_outline_levels = { "num", "ABC" }
      helpers.new_buffer({
        "# Hello there",
        "1. this is the first bullet",
        "\t- standard bullet",
      })
      -- GA enters insert at end, CR on bullet line (standard bullet), type
      helpers.feedkeys("GA<CR>second standard bullet<Esc>")
      -- CR on bullet line, promote with <C-d>, type
      helpers.feedkeys("A<CR><C-d>second bullet<Esc>")
      -- CR on bullet line, type
      helpers.feedkeys("A<CR>third bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "1. this is the first bullet",
        "\t- standard bullet",
        "\t- second standard bullet",
        "2. second bullet",
        "3. third bullet",
      }, helpers.get_lines())
    end)

    it("adds new nested bullets with correct alpha/roman numerals", function()
      helpers.new_buffer({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
      })
      -- All CRs are on bullet lines. After <C-t>, insert mode remains active
      -- so the sequence can continue by typing text and pressing <CR> for the next line.
      helpers.feedkeys(
        "GA<CR>third bullet<C-t><CR>fourth bullet<C-t><CR>fifth bullet<C-t><CR>sixth bullet<C-t><CR>seventh bullet<Esc>"
      )
      helpers.feedkeys(
        "A<CR>eighth bullet<C-d><CR>ninth bullet<C-d><CR>tenth bullet<C-d><CR>eleventh bullet<C-d><CR>twelfth bullet<C-d><Esc>"
      )
      assert.are.same({
        "# Hello there",
        "I. this is the first bullet",
        "\tA. second bullet",
        "\t\t1. third bullet",
        "\t\t\ta. fourth bullet",
        "\t\t\t\ti. fifth bullet",
        "\t\t\t\t\t- sixth bullet",
        "\t\t\t\t\t- seventh bullet",
        "\t\t\t\tii. eighth bullet",
        "\t\t\tb. ninth bullet",
        "\t\t2. tenth bullet",
        "\tB. eleventh bullet",
        "II. twelfth bullet",
      }, helpers.get_lines())
    end)

    it("changes levels in visual mode", function()
      vim.g.bullets_outline_levels = { "num", "abc", "std*" }
      helpers.new_buffer({
        "# Hello there",
        "1. first bullet",
        "\ta. second bullet",
        "\tb. third bullet",
        "\t\t* fourth bullet",
        "\t\t* fifth bullet",
        "\t\t\tsixth bullet",
        "\t\t* seventh bullet",
        "2. eighth bullet",
        "\t\ta. ninth bullet",
        "\ta. tenth bullet",
        "\tb. eleventh bullet",
        "3. twelfth bullet",
        "\t thirteenth bullet",
        "\ta. fourteenth bullet",
        "\t\t* fifteenth bullet",
        "4. sixteenth bullet",
      })
      -- After each visual < or > operation, the plugin re-enters visual mode (via s:set_selection).
      -- Exit visual mode before starting each fresh visual selection.
      helpers.feedkeys("gg3jv<")
      helpers.feedkeys("<Esc>jv2j<")
      helpers.feedkeys("<Esc>jvj>")
      helpers.feedkeys("<Esc>jvj<")
      -- The plugin leaves us in visual mode with the same selection.
      helpers.feedkeys("<")
      helpers.feedkeys("<Esc>jv>")
      helpers.feedkeys("<Esc>3jv2j>")
      -- Repeat the operation on the same visual selection.
      helpers.feedkeys(">")
      assert.are.same({
        "# Hello there",
        "1. first bullet",
        "\ta. second bullet",
        "2. third bullet",
        "\ta. fourth bullet",
        "\tb. fifth bullet",
        "\t\tsixth bullet",
        "\t\t\t* seventh bullet",
        "\tc. eighth bullet",
        "3. ninth bullet",
        "tenth bullet",
        "\t\ta. eleventh bullet",
        "4. twelfth bullet",
        "\t thirteenth bullet",
        "\t\t\ta. fourteenth bullet",
        "\t\t\t\t* fifteenth bullet",
        "\t\ta. sixteenth bullet",
      }, helpers.get_lines())
    end)

    it("add and change bullets with multiple line spacing and wrapped lines", function()
      vim.g.bullets_line_spacing = 2
      helpers.new_buffer({
        "# Hello there",
        "I. this is the first bullet",
      })
      -- GA enters insert at end, CR on bullet line (with line_spacing=2, creates empty line too)
      -- Then type 'second bullet', then CR again, demote, type 'third bullet'
      helpers.feedkeys("GA<CR>second bullet<Esc>")
      helpers.feedkeys("A<CR><C-t>third bullet<Esc>")
      -- After CR on bullet line with line_spacing=2, cursor is on the new empty line after the bullet
      -- dd deletes that line, then inserts '\twrapped bullet'.
      helpers.feedkeys("A<CR>")
      helpers.feedkeys("dd")
      helpers.feedkeys("i\twrapped bullet<Esc>")
      -- Then CR, type 'fourth bullet'
      helpers.feedkeys("A<CR>fourth bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "I. this is the first bullet",
        "",
        "II. second bullet",
        "",
        "\tA. third bullet",
        "\twrapped bullet",
        "",
        "\tB. fourth bullet",
      }, helpers.get_lines())
    end)

    it("indents after a line ending in a colon", function()
      vim.g.bullets_auto_indent_after_colon = 1
      helpers.new_buffer({
        "# Hello there",
        "a. this is the first bullet",
      })
      -- GA enters insert at end, CR on bullet line, type second bullet ending with colon
      helpers.feedkeys("GA<CR>this is the second bullet:<Esc>")
      -- CR after colon should auto-indent
      helpers.feedkeys("A<CR>this bullet is indented<Esc>")
      helpers.feedkeys("A<CR>this bullet is also indented<Esc>")
      -- Check first phase
      local lines1 = helpers.get_lines()
      -- Remove trailing empty lines before comparison.
      while #lines1 > 0 and lines1[#lines1] == "" do
        table.remove(lines1)
      end
      assert.are.same({
        "# Hello there",
        "a. this is the first bullet",
        "b. this is the second bullet:",
        "\ti. this bullet is indented",
        "\tii. this bullet is also indented",
      }, lines1)

      -- Phase 2: reset buffer with same content, test fullwidth colon
      helpers.new_buffer({
        "# Hello there",
        "a. this is the first bullet",
      })
      -- Use GA to enter insert at end of the last line.
      helpers.feedkeys("GA<CR>this is the second bullet that ends with fullwidth colon：<Esc>")
      helpers.feedkeys("A<CR>this bullet is indented<Esc>")
      helpers.feedkeys("A<CR>this bullet is also indented<Esc>")
      local lines2 = helpers.get_lines()
      while #lines2 > 0 and lines2[#lines2] == "" do
        table.remove(lines2)
      end
      assert.are.same({
        "# Hello there",
        "a. this is the first bullet",
        "b. this is the second bullet that ends with fullwidth colon：",
        "\ti. this bullet is indented",
        "\tii. this bullet is also indented",
      }, lines2)
    end)
  end)
end)
