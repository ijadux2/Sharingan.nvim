-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Load core settings first
require("core.options")
require("core.keymaps")

-- Setup lazy.nvim with spec directory
require("lazy").setup({
	spec = {
		{ import = "plugins.ui" },
		{ import = "plugins.lsp" },
		{ import = "plugins.tools" },
		{ import = "plugins.filetypes" },
		{ import = "plugins.extras" },
	},
	defaults = { lazy = false, version = false },
	checker = { enabled = false },
	install = { colorscheme = {} },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
				"netrwPlugin",
			},
		},
	},
})

-- Load custom modules
require("tangle").setup()

-- Load custom utilities
local modules = {
	"agenda",
	"app-launcher",
	"emoji",
	"fuzzy",
	"git",
	"git-branch",
	"git-commit",
	"power-commands",
	"screenshot",
	"text-browser",
	"todo",
	"web-search",
}

for _, mod in ipairs(modules) do
	local ok, mod_val = pcall(require, mod)
	if not ok then
		vim.notify("[init] Failed to load: " .. mod, vim.log.levels.WARN)
	elseif mod_val and mod_val.setup then
		mod_val.setup()
	end
end

-- Set colorscheme at the end
vim.cmd.colorscheme("catppuccin")
