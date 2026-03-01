-- Basic Neovim settings
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
})
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.guifont = "JetBrainsMono Nerd Font:h15"
vim.opt.cursorline = true
--vim.opt.pumblend = 100 -- blur for nvim
--vim.opt.winblend = 100 -- blur for nvim as window
vim.opt.showtabline = 2
vim.opt.linebreak = true
vim.opt.guicursor = "n-v-c-i:block"

-- Netrw settings
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4
vim.g.netrw_winsize = 25
vim.g.netrw_banner = 0

-- LSP diagnostics configuration (spell hints disabled)
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	-- Disable spelling hints (HINT severity)
	virtual_text = {
		severity = {
			min = vim.diagnostic.severity.WARN,
		},
	},
	signs = {
		severity = {
			min = vim.diagnostic.severity.WARN,
		},
	},
	underline = {
		severity = {
			min = vim.diagnostic.severity.WARN,
		},
	},
})

-- Spell checking disabled
vim.opt.spell = false
vim.opt.spelllang = {} --"en_us"

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	callback = function()
		vim.hl.on_yank()
	end,
})
