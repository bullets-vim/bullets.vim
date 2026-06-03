local helpers = require("test.helpers")

describe("Bullets.vim", function()
  describe("alphabetic bullets", function()
    before_each(function()
      helpers.reset_config()
    end)

    it("adds a new upper case bullet", function()
      helpers.new_buffer({
        "# Hello there",
        "A. this is the first bullet",
      })
      helpers.feedkeys(
        "A<CR>second bullet<CR>third bullet<CR>fourth bullet<CR>fifth bullet"
          .. "<CR>sixth bullet<CR>seventh bullet<CR>eighth bullet<CR>ninth bullet<CR>tenth bullet<Esc>"
      )
      assert.are.same({
        "# Hello there",
        "A. this is the first bullet",
        "B. second bullet",
        "C. third bullet",
        "D. fourth bullet",
        "E. fifth bullet",
        "F. sixth bullet",
        "G. seventh bullet",
        "H. eighth bullet",
        "I. ninth bullet",
        "J. tenth bullet",
      }, helpers.get_lines())
    end)

    it("adds a new lower case bullet", function()
      helpers.new_buffer({
        "# Hello there",
        "a. this is the first bullet",
      })
      helpers.feedkeys(
        "A<CR>second bullet<CR>third bullet<CR>fourth bullet<CR>fifth bullet"
          .. "<CR>sixth bullet<CR>seventh bullet<CR>eighth bullet<CR>ninth bullet<CR>tenth bullet<Esc>"
      )
      assert.are.same({
        "# Hello there",
        "a. this is the first bullet",
        "b. second bullet",
        "c. third bullet",
        "d. fourth bullet",
        "e. fifth bullet",
        "f. sixth bullet",
        "g. seventh bullet",
        "h. eighth bullet",
        "i. ninth bullet",
        "j. tenth bullet",
      }, helpers.get_lines())
    end)

    it("adds a new bullet and loops at z", function()
      vim.g.bullets_renumber_on_change = 0
      helpers.new_buffer({
        "# Hello there",
        "y. this is the first bullet",
      })
      -- Type through "third bullet", then press CR twice:
      -- first CR inserts "ab. " (next bullet after "aa."),
      -- second CR on empty bullet line triggers delete-last-bullet-if-empty,
      -- leaving an empty line in normal mode.
      helpers.feedkeys("A<CR>second bullet<CR>third bullet<CR><CR>")
      -- Now in normal mode on empty line 5. Use 'A' to enter insert at end,
      -- type the override bullet, then continue with remaining bullets.
      helpers.feedkeys("AAY. fourth bullet<CR>fifth bullet<CR>sixth bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "y. this is the first bullet",
        "z. second bullet",
        "aa. third bullet",
        "AY. fourth bullet",
        "AZ. fifth bullet",
        "BA. sixth bullet",
      }, helpers.get_lines())
    end)

    it("does not add a new bullet when mixed case", function()
      -- "Ab." is mixed case so the plugin doesn't recognise it as a bullet.
      -- CR is therefore deferred via feedkeys('n'); the 'tx' flag in our outer
      -- feedkeys drains that deferred CR, leaving normal mode on a new empty line.
      -- Use the two-step non-bullet-line pattern.
      helpers.new_buffer({
        "# Hello there",
        "Ab. this is the first bullet",
      })
      helpers.feedkeys("A<CR>")
      helpers.feedkeys("inot a bullet<Esc>")
      assert.are.same({
        "# Hello there",
        "Ab. this is the first bullet",
        "not a bullet",
      }, helpers.get_lines())
    end)

    describe("g:bullets_max_alpha_characters", function()
      it("stops adding items after configured max (default 2)", function()
        vim.g.bullets_renumber_on_change = 0
        helpers.new_buffer({
          "# Hello there",
          "zy. this is the first bullet",
        })
        -- "A<CR>" inserts "zz. " (within max), type "second bullet",
        -- then <CR> on the "zz. second bullet" line: next would be "aaa." (3
        -- chars) which exceeds the default max of 2, so no bullet is inserted;
        -- instead a plain CR is deferred. The 'tx' flag drains it, leaving
        -- normal mode on a new empty line.
        helpers.feedkeys("A<CR>second bullet<CR>")
        helpers.feedkeys("inot a bullet<Esc>")
        assert.are.same({
          "# Hello there",
          "zy. this is the first bullet",
          "zz. second bullet",
          "not a bullet",
        }, helpers.get_lines())
      end)

      it("does not bullets if configured as 0", function()
        vim.g.bullets_max_alpha_characters = 0
        helpers.new_buffer({
          "# Hello there",
          "a. this is the first bullet",
        })
        -- With max=0, alpha bullets are disabled entirely so "a." is not
        -- recognized as a bullet → CR defers via feedkeys('n')
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("inot a bullet<Esc>")
        assert.are.same({
          "# Hello there",
          "a. this is the first bullet",
          "not a bullet",
        }, helpers.get_lines())
      end)
    end)
  end)
end)
