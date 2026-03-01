--------------------------------------------------------------------------------
-- Tools & Utilities Plugins
-- File: lua/plugins/tools.lua
-- Description: Development tools, file search, git integration, and utilities
--
-- CONTENTS:
--   1. Telescope (Fuzzy file finder)
--   2. Plenary (Common Lua utilities - dependency)
--   3. Gitsigns (Git integration)
--   4. Trouble (Diagnostics viewer)
--   5. Todo-comments (TODO/FIXME highlighting)
--   6. Yazi (File manager)
--   7. Cloak (Hide sensitive data)
--------------------------------------------------------------------------------

return {
	--------------------------------------------------------------------------------
	-- SECTION 1: Telescope
	-- Fuzzy finder for files, grep, buffers, and more
	-- Features: Fast fuzzy search, preview, multi-select
	-- Keybindings:
	--   <leader>f - Find files
	--   <leader>lg - Live grep (search in files)
	--------------------------------------------------------------------------------
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",  -- Required dependency
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- Fuzzy algorithm
		},
		config = function()
			local builtin = require("telescope.builtin")
			-- <leader>f - Find files in current directory
			vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Telescope find files" })
			-- <leader>lg - Live grep (search text in files)
			vim.keymap.set("n", "<leader>lg", builtin.live_grep, { desc = "Telescope live grep" })
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 2: Plenary
	-- Common Lua utilities used by many plugins
	-- Required by: Telescope, Yazi, and others
	--------------------------------------------------------------------------------
	{ "nvim-lua/plenary.nvim", lazy = true },

	--------------------------------------------------------------------------------
	-- SECTION 3: Gitsigns
	-- Git integration showing changes in the gutter
	-- Features: Added/modified/deleted lines, blame, hunk actions
	--------------------------------------------------------------------------------
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 4: Trouble
	-- Diagnostics and LSP reference viewer
	-- Shows: Errors, warnings, references, definitions in a list
	-- Keybinding: <S-c> - Toggle diagnostics
	--------------------------------------------------------------------------------
	{
		"folke/trouble.nvim",
		opts = {},
		cmd = "Trouble",
		keys = {
			{
				"<S-c>",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
		},
	},

	--------------------------------------------------------------------------------
	-- SECTION 5: Todo-comments
	-- Highlight and search for TODO, FIXME, HACK, etc.
	-- Features: Icons in gutter, keyword highlighting, jump to comments
	--------------------------------------------------------------------------------
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			-- Show icons in the sign column
			signs = true,
			sign_priority = 8,
			-- Keywords recognized as todo comments
			keywords = {
				-- FIX: Bug fixes and issues
				FIX = {
					icon = " ",
					color = "error",
					alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
				},
				-- TODO: Tasks to do
				TODO = { icon = " ", color = "info" },
				-- HACK: Workarounds
				HACK = { icon = " ", color = "warning" },
				-- WARN: Warnings
				WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
				-- PERF: Performance improvements
				PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
				-- NOTE: Important notes
				NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
				-- TEST: Test-related
				TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
			},
			-- GUI style for keywords
			gui_style = {
				fg = "NONE",
				bg = "BOLD",
			},
			-- Merge custom keywords with defaults
			merge_keywords = true,
			-- Highlight settings
			highlight = {
				multiline = true,       -- Support multiline comments
				multiline_pattern = "^.",
				multiline_context = 10,
				before = "",
				keyword = "wide",
				after = "fg",
				pattern = [[.*<(KEYWORDS)\s*:]],
				comments_only = true,    -- Only in comments
				max_line_len = 400,
				exclude = {},
			},
			-- Color mappings
			colors = {
				error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
				warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
				info = { "DiagnosticInfo", "#2563EB" },
				hint = { "DiagnosticHint", "#10B981" },
				default = { "Identifier", "#7C3AED" },
				test = { "Identifier", "#FF00FF" },
			},
			-- Search configuration
			search = {
				command = "rg",
				args = {
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
				},
				pattern = [[\b(KEYWORDS):]],
			},
		},
	},

	--------------------------------------------------------------------------------
	-- SECTION 6: Yazi
	-- Blazingly fast file manager written in Rust
	-- Features: Async operations, visual selection, bulk rename
	-- Keybindings:
	--   <leader>- - Open yazi at current file
	--   ] - Open yazi at cwd
	--   <c-up> - Resume last yazi session
	--------------------------------------------------------------------------------
	{
		"mikavilpas/yazi.nvim",
		version = "*",
		event = "VeryLazy",
		dependencies = {
			{ "nvim-lua/plenary.nvim", lazy = true },
		},
		keys = {
			{
				"<leader>-",
				mode = { "n", "v" },
				"<cmd>Yazi<cr>",
				desc = "Open yazi at the current file",
			},
			{
				"]",
				"<cmd>Yazi cwd<cr>",
				desc = "Open the file manager in nvim's working directory",
			},
			{
				"<c-up>",
				"<cmd>Yazi toggle<cr>",
				desc = "Resume the last yazi session",
			},
		},
		opts = {
			open_for_directories = false,
			keymaps = {
				show_help = "<f1>",
			},
		},
		init = function()
			-- Disable netrw (built-in file explorer)
			vim.g.loaded_netrwPlugin = 1
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 7: Cloak
	-- Hide sensitive data in files (passwords, API keys, tokens)
	-- Shows: Masked characters (default: *) instead of actual values
	-- Pattern: Matches .env files and masks values after =
	--------------------------------------------------------------------------------
	{
		"laytan/cloak.nvim",
		config = function()
			require("cloak").setup({
				enabled = true,
				cloak_character = "*",  -- Character to mask with
				-- Highlight group for masked text
				highlight_group = "Comment",
				-- Patterns to cloak
				patterns = {
					{
						-- Match any file starting with '.env'
						file_pattern = ".env*",
						-- Match everything after the = sign
						cloak_pattern = "=.+",
					},
				},
			})
		end,
	},
}
