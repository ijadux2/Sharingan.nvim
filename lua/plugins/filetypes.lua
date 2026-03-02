--------------------------------------------------------------------------------
-- Language & Filetype Plugins
-- File: lua/plugins/filetypes.lua
-- Description: Plugins for specific file types and languages
--
-- CONTENTS:
--   1. Render-markdown (Markdown preview)
--   2. Obsidian (Obsidian vault integration)
--   3. nvim-nu (Nushell support)
--   4. image.nvim (Image viewer)
--   5. Shell (Terminal commands)
--   6. Popup Terminal (Floating terminal)
--   7. vim-be-good (Game to improve vim skills)
--------------------------------------------------------------------------------

return {
	--------------------------------------------------------------------------------
	-- SECTION 1: Render-markdown
	-- Preview Markdown files with syntax highlighting
	-- Features: Code blocks, tables, checkboxes, headings
	--------------------------------------------------------------------------------
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter", -- Syntax highlighting
			"nvim-mini/mini.nvim",
			"nvim-mini/mini.icons",
		},
		opts = {},
	},

	--------------------------------------------------------------------------------
	-- SECTION 2: Obsidian
	-- Obsidian vault integration for note-taking
	-- Features: Wiki-links, backlinks, daily notes, search
	-- Path: ~/notes/Markdowns/
	--------------------------------------------------------------------------------
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		lazy = true,
		ft = "markdown", -- Only load for markdown files
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = {
			-- Vault configuration
			workspaces = {
				{
					name = "personal",
					path = "~/notes/Markdowns/",
				},
			},
		},
	},

	--------------------------------------------------------------------------------
	-- SECTION 3: nvim-nu
	-- Nushell language support
	-- Features: Syntax highlighting, LSP features
	--------------------------------------------------------------------------------
	{
		"LhKipp/nvim-nu",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		ft = { "nu" }, -- Only for .nu files
		config = function()
			require("nu").setup({
				use_lsp_features = false,
				-- Command names pattern
				all_cmd_names = [[^#\s*script-execution-hash\s*.*$\n]],
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 4: image.nvim
	-- View images in Neovim
	-- Uses: ImageMagick CLI for processing
	--------------------------------------------------------------------------------
	{
		"3rd/image.nvim",
		build = false, -- Don't build, use pre-built
		opts = {
			processor = "magick_cli", -- Use ImageMagick CLI
		},
	},

	--------------------------------------------------------------------------------
	-- SECTION 5: Shell Command
	-- Custom :Shell command for running terminal commands
	-- Opens: Terminal in bottom panel
	-- Usage: :Shell <command>
	--------------------------------------------------------------------------------
	{
		"none", -- Virtual plugin (no actual plugin)
		virtual = true,
		config = function()
			vim.api.nvim_create_user_command("Shell", function(opts)
				local cmd = opts.args
				local buf = vim.api.nvim_create_buf(false, true)
				-- Calculate dimensions (wider, at bottom)
				local width = math.ceil(vim.o.columns * 0.9)
				local height = cmd == "" and math.ceil(vim.o.lines * 0.8) or 10
				local row = vim.o.lines - height - 3
				local col = math.ceil((vim.o.columns - width) / 2)
				-- Open floating window
				local win = vim.api.nvim_open_win(buf, true, {
					relative = "editor",
					width = width,
					height = height,
					row = row,
					col = col,
					style = "minimal",
					border = "rounded",
					title = " " .. (cmd ~= "" and "  " .. cmd or " Zsh ") .. " ",
					title_pos = "left",
				})
				-- Execute command
				local exec_args = cmd ~= "" and { "zsh", "-c", cmd } or { "zsh" }
				vim.fn.termopen(exec_args, {
					cwd = vim.fn.getcwd(),
					on_exit = function() end,
				})
				-- Keybindings to close
				vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
				vim.keymap.set("n", "<Esc>", ":close<CR>", { buffer = buf, silent = true })
				-- Enter insert mode
				vim.cmd("startinsert")
			end, {
				nargs = "*",
				complete = "shellcmd",
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 6: Popup Terminal
	-- Floating terminal window (centered)
	-- Usage: :Shell <command>
	--------------------------------------------------------------------------------
	{
		"none", -- Virtual plugin
		virtual = true,
		config = function()
			vim.api.nvim_create_user_command("Shell", function(opts)
				local cmd = opts.args
				local buf = vim.api.nvim_create_buf(false, true)
				-- Centered dimensions
				local width = math.ceil(vim.o.columns * 0.8)
				local height = math.ceil(vim.o.lines * 0.8)
				local row = math.ceil((vim.o.lines - height) / 2 - 1)
				local col = math.ceil((vim.o.columns - width) / 2)
				-- Open centered floating window
				local win = vim.api.nvim_open_win(buf, true, {
					relative = "editor",
					width = width,
					height = height,
					row = row,
					col = col,
					style = "minimal",
					border = "rounded",
					title = " " .. (cmd ~= "" and "Exec: " .. cmd or "zsh") .. " ",
					title_pos = "center",
				})
				-- Execute command
				local exec_args = cmd ~= "" and { "zsh", "-c", cmd } or { "zsh" }
				vim.fn.termopen(exec_args, {
					cwd = vim.fn.getcwd(),
				})
				-- Enter insert mode
				vim.cmd("startinsert")
				-- q to close
				vim.keymap.set("n", "q", function()
					if vim.api.nvim_win_is_valid(win) then
						vim.api.nvim_win_close(win, true)
					end
				end, { buffer = buf, silent = true })
			end, {
				nargs = "*",
				complete = "shellcmd",
				desc = "Run zsh command or interactive shell in a float",
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 7: vim-be-good
	-- Game to improve Vim movement skills
	-- Teaches: h,j,k,l navigation, word motions, etc.
	--------------------------------------------------------------------------------
	{ "ThePrimeagen/vim-be-good" },
}
