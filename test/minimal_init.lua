-- Resolve the repo root relative to this file's location
local script_path = debug.getinfo(1, "S").source:sub(2) -- strip leading '@'
local repo_root = vim.fn.fnamemodify(script_path, ":p:h:h")

local plenary_path = "/tmp/plenary.nvim"
if not vim.uv.fs_stat(plenary_path) then
  vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/nvim-lua/plenary.nvim", plenary_path })
end

vim.opt.rtp:prepend(plenary_path)
vim.opt.rtp:prepend(repo_root)

vim.cmd("filetype plugin on")
vim.cmd("runtime plugin/bullets.vim")
vim.cmd("set formatoptions=")
vim.cmd("set noexpandtab")
