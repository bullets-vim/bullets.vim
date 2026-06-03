local helpers = require("test.helpers")

describe("checkboxes", function()
  describe("inserting checkboxes", function()
    it("inserts another checkbox after the previous one", function()
      helpers.test_bullet_inserted(
        "do that",
        { "# Hello there", "- [ ] do this" },
        { "# Hello there", "- [ ] do this", "- [ ] do that" }
      )
    end)

    it("inserts a * checkbox after the previous one", function()
      helpers.test_bullet_inserted(
        "do that",
        { "# Hello there", "* [ ] do this" },
        { "# Hello there", "* [ ] do this", "* [ ] do that" }
      )
    end)

    it("inserts an empty checkbox even if prev line was checked", function()
      helpers.test_bullet_inserted(
        "do that",
        { "# Hello there", "- [x] do this" },
        { "# Hello there", "- [x] do this", "- [ ] do that" }
      )
    end)
  end)

  describe("toggling checkboxes", function()
    before_each(function()
      helpers.reset_config()
    end)

    it("toggle a bullet", function()
      helpers.new_buffer({
        "# Hello there",
        "- [ ] first bullet",
        "- [X] second bullet",
        "- [x] third bullet",
        "- [.] fourth bullet",
        "- [o] fifth bullet",
        "- [O] sixth bullet",
        "- not a checkbox",
      })
      -- Move to line 2 (first bullet line), then toggle each
      helpers.feedkeys("gg")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      assert.are.same({
        "# Hello there",
        "- [X] first bullet",
        "- [ ] second bullet",
        "- [ ] third bullet",
        "- [X] fourth bullet",
        "- [X] fifth bullet",
        "- [X] sixth bullet",
        "- not a checkbox",
      }, helpers.get_lines())
    end)

    it("toggle a bullet and adjust parent", function()
      helpers.new_buffer({
        "# Hello there",
        "- [ ] first bullet",
        "  - [ ] second bullet",
        "    - [ ] third bullet",
      })
      helpers.feedkeys("G")
      vim.cmd("ToggleCheckbox")
      assert.are.same({
        "# Hello there",
        "- [X] first bullet",
        "  - [X] second bullet",
        "    - [X] third bullet",
      }, helpers.get_lines())
    end)

    it("toggle a bullet and adjust children", function()
      helpers.new_buffer({
        "# Hello there",
        "- [ ] first bullet",
        "  - [ ] second bullet",
        "    - [ ] third bullet",
      })
      helpers.feedkeys("ggj")
      vim.cmd("ToggleCheckbox")
      assert.are.same({
        "# Hello there",
        "- [X] first bullet",
        "  - [X] second bullet",
        "    - [X] third bullet",
      }, helpers.get_lines())
    end)

    it("toggle a bullet and calculate completion", function()
      helpers.new_buffer({
        "# Hello there",
        "- [ ] first bullet",
        "  - [ ] second bullet",
        "    - [ ] third bullet",
        "    - [ ] fourth bullet",
        "    - [ ] fifth bullet",
        "    - [ ] sixth bullet",
        "  - [ ] seventh bullet",
        "    - [ ] eighth bullet",
        "    - [ ] ninth bullet",
        "    - [ ] tenth bullet",
        "    - [ ] eleventh bullet",
        "  - [ ] twelfth bullet",
        "    - [ ] thirteenth bullet",
        "    - [ ] fourteenth bullet",
        "    - [ ] fifteenth bullet",
        "    - [ ] sixteenth bullet",
        "  - [X] seventeenth bullet",
        "    - [X] eighteenth bullet",
        "    - [X] ninteenth bullet",
        "    - [X] twentieth bullet",
        "    - [X] twenty-first bullet",
      })
      -- cursor starts at last line (line 21), go to line 4 (3j from top = line 4)
      -- new_buffer places cursor at last line, so we need to go to line 4
      helpers.feedkeys("gg")
      helpers.feedkeys("3j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("6j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("2j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      helpers.feedkeys("2j")
      vim.cmd("ToggleCheckbox")
      assert.are.same({
        "# Hello there",
        "- [.] first bullet",
        "  - [.] second bullet",
        "    - [X] third bullet",
        "    - [ ] fourth bullet",
        "    - [ ] fifth bullet",
        "    - [ ] sixth bullet",
        "  - [O] seventh bullet",
        "    - [ ] eighth bullet",
        "    - [X] ninth bullet",
        "    - [X] tenth bullet",
        "    - [X] eleventh bullet",
        "  - [X] twelfth bullet",
        "    - [X] thirteenth bullet",
        "    - [X] fourteenth bullet",
        "    - [X] fifteenth bullet",
        "    - [X] sixteenth bullet",
        "  - [O] seventeenth bullet",
        "    - [ ] eighteenth bullet",
        "    - [X] ninteenth bullet",
        "    - [X] twentieth bullet",
        "    - [X] twenty-first bullet",
      }, helpers.get_lines())
    end)

    it("adds and toggles bullets using UTF characters", function()
      vim.g.bullets_checkbox_markers = "✗○◐●✓"
      -- Ensure <C-t> produces tabs (not spaces) regardless of user config
      vim.opt.expandtab = false
      helpers.new_buffer({
        "# Hello there",
        "- [ ] first bullet",
      })
      -- Toggle first bullet (cursor at line 2 already via new_buffer)
      helpers.feedkeys("j")
      vim.cmd("ToggleCheckbox")
      -- Open new line and type "second bullet"
      helpers.feedkeys("osecond bullet<Esc>")
      -- Open new line with indent and type "third bullet"
      helpers.feedkeys("o<C-t>third bullet<Esc>")
      -- Open new line (same indent) and type "fourth bullet", then toggle
      helpers.feedkeys("ofourth bullet<Esc>")
      vim.cmd("ToggleCheckbox")
      -- Open new line with dedent and type "fifth bullet", then toggle
      helpers.feedkeys("o<C-d>fifth bullet<Esc>")
      vim.cmd("ToggleCheckbox")
      -- Open new line and type "sixth bullet", toggle twice
      helpers.feedkeys("osixth bullet<Esc>")
      vim.cmd("ToggleCheckbox")
      vim.cmd("ToggleCheckbox")
      assert.are.same({
        "# Hello there",
        "- [✓] first bullet",
        "- [◐] second bullet",
        "\t- [✗] third bullet",
        "\t- [✓] fourth bullet",
        "- [✓] fifth bullet",
        "- [✗] sixth bullet",
      }, helpers.get_lines())
    end)

    it("recomputes checkboxes recursively on RecomputeCheckboxes", function()
      vim.g.bullets_checkbox_markers = " .¼½¾X"
      helpers.new_buffer({
        "# Hello there",
        "- [ ] EXPECTED: ¼",
        "  - [X] checkbox leaf",
        "  - [ ] EXPECTED: CHECKED",
        "    - [ ] EXPECTED: CHECKED",
        "      - [ ] EXPECTED: CHECKED",
        "        - [X] checkbox leaf",
        "    - [X] checkbox leaf",
        "  - [X] EXPECTED: ¾",
        "    - [X] checkbox leaf",
        "    - [X] checkbox leaf",
        "    - [X] checkbox leaf",
        "    - [ ] checkbox leaf",
        "  - [X] EXPECTED: ½",
        "    - [ ] EXPECTED: CHECKED",
        "      - [ ] EXPECTED: CHECKED",
        "        - [X] checkbox leaf",
        "    - [½] checkbox leaf (EXPECTED: UNCHECKED)",
        "  - [½] EXPECTED: UNCHECKED",
        "    - [ ] checkbox leaf",
        "    - [½] checkbox leaf (EXPECTED: UNCHECKED)",
      })
      helpers.feedkeys("gg")
      helpers.feedkeys("9j")
      vim.cmd("RecomputeCheckboxes")
      assert.are.same({
        "# Hello there",
        "- [¼] EXPECTED: ¼",
        "  - [X] checkbox leaf",
        "  - [X] EXPECTED: CHECKED",
        "    - [X] EXPECTED: CHECKED",
        "      - [X] EXPECTED: CHECKED",
        "        - [X] checkbox leaf",
        "    - [X] checkbox leaf",
        "  - [¾] EXPECTED: ¾",
        "    - [X] checkbox leaf",
        "    - [X] checkbox leaf",
        "    - [X] checkbox leaf",
        "    - [ ] checkbox leaf",
        "  - [½] EXPECTED: ½",
        "    - [X] EXPECTED: CHECKED",
        "      - [X] EXPECTED: CHECKED",
        "        - [X] checkbox leaf",
        "    - [ ] checkbox leaf (EXPECTED: UNCHECKED)",
        "  - [ ] EXPECTED: UNCHECKED",
        "    - [ ] checkbox leaf",
        "    - [ ] checkbox leaf (EXPECTED: UNCHECKED)",
      }, helpers.get_lines())
    end)

    it("recomputes checkboxes correctly on reindents", function()
      vim.g.bullets_checkbox_markers = " /X"
      helpers.new_buffer({
        "# Hello there",
        "- [X] parent bullet",
        "  - [X] first child bullet",
      })
      -- Press CR at end of last line to add a new child bullet
      helpers.feedkeys("GA<CR>")
      vim.cmd("RecomputeCheckboxes")
      assert.are.same({
        "# Hello there",
        "- [/] parent bullet",
        "  - [X] first child bullet",
        "  - [ ] ",
      }, helpers.get_lines())

      -- Phase 2: press CR on the new empty bullet, which should dedent/remove it
      vim.g.bullets_delete_last_bullet_if_empty = 2
      helpers.feedkeys("A<CR>")
      vim.cmd("RecomputeCheckboxes")
      assert.are.same({
        "# Hello there",
        "- [X] parent bullet",
        "  - [X] first child bullet",
        "- [ ] ",
      }, helpers.get_lines())
    end)

    it("handles skip-level checkbox trees", function()
      vim.g.bullets_checkbox_markers = " /X"
      helpers.new_buffer({
        "# Hello there",
        "- [X] parent bullet (EXPECTED: /)",
        "  - skip: not checkbox content",
        "    - [ ] new root bullet (EXPECTED: /)",
        "      - [ ] first child bullet",
        "      - [X] first child bullet",
        "  - [X] first child bullet",
        "  - [ ] first child bullet",
      })
      helpers.feedkeys("gg")
      helpers.feedkeys("2j")
      vim.cmd("RecomputeCheckboxes")
      assert.are.same({
        "# Hello there",
        "- [/] parent bullet (EXPECTED: /)",
        "  - skip: not checkbox content",
        "    - [/] new root bullet (EXPECTED: /)",
        "      - [ ] first child bullet",
        "      - [X] first child bullet",
        "  - [X] first child bullet",
        "  - [ ] first child bullet",
      }, helpers.get_lines())
    end)
  end)
end)
