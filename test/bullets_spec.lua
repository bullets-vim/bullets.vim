local helpers = require("test.helpers")

describe("Bullets.vim", function()
	describe("inserting new bullets", function()
		it("adds a new bullet if the previous line had a known bullet type", function()
			helpers.test_bullet_inserted(
				"do that",
				{ "# Hello there", "- do this" },
				{ "# Hello there", "- do this", "- do that" }
			)
		end)
	end)
end)
