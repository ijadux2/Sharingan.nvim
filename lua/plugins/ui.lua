--------------------------------------------------------------------------------
-- UI & Theme Plugins
-- File: lua/plugins/ui.lua
-- Description: All visual and user interface related plugins consolidated into one file
--
-- CONTENTS:
--   1. LazyVim (Core framework - required)
--   2. Catppuccin (Main colorscheme)
--   3. Alternative Themes (tokyonight, kanagawa, gruvbox, etc.)
--   4. Lualine (Status line)
--   5. Bufferline (Buffer tabs)
--   6. Snacks (Dashboard, Picker, Notifier)
--   7. Mini.icons (File icons)
--   8. Which-key (Keybinding hints)
--   9. Noice (Enhanced messages/cmdline)
--   10. Paint (Custom highlights)
--------------------------------------------------------------------------------

return {
	--------------------------------------------------------------------------------
	-- SECTION 1: LazyVim Core Framework
	-- The base framework that provides plugin management and defaults
	--------------------------------------------------------------------------------
	{ "LazyVim/LazyVim" },

	--------------------------------------------------------------------------------
	-- SECTION 2: Catppuccin Theme
	-- Main colorscheme - Beautiful purple-tinted dark theme
	-- Features: Multiple flavors (mocha/latte/frappe/macchiato), transparency,
	--           LSP diagnostic undercurl, 25+ plugin integrations
	--------------------------------------------------------------------------------
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				-- Theme flavor: mocha (dark purple), latte (light), frappe, macchiato
				flavour = "mocha",
				-- Enable transparent background for terminal transparency
				transparent_background = true,
				-- Use terminal native colors
				term_colors = true,
				-- Custom highlights for LSP diagnostic underlines
				-- Shows colored underlines under errors, hints, warnings, info
				custom_highlights = function(colors)
					return {
						DiagnosticUnderlineError = { sp = colors.red, undercurl = true },
						DiagnosticUnderlineHint = { sp = colors.teal, undercurl = true },
						DiagnosticUnderlineWarn = { sp = colors.yellow, undercurl = true },
						DiagnosticUnderlineInfo = { sp = colors.sky, undercurl = true },
					}
				end,
				-- Custom color palette overrides for mocha flavor
				color_overrides = {
					mocha = {
						base = "#181425",      -- Main background
						mantle = "#161320",    -- Sidebar background
						crust = "#110f1a",     -- Border background
						surface0 = "#2d2a3e",  -- Surface gray
						text = "#cdd6f4",       -- Main text
						subtext0 = "#a69db1",  -- Subtle text
						lavender = "#b4befe",  -- Lavender accent
						mauve = "#cba6f7",    -- Mauve accent
						sapphire = "#89dceb",  -- Blue accent
						blue = "#89b4fa",      -- Primary blue
					},
				},
				-- Integration with other plugins for seamless theming
				-- Each integration applies custom colors for that plugin
				integrations = {
					aerial = true,           -- Code outline sidebar
					alpha = true,            -- Startup screen
					cmp = true,              -- Completion menu
					oil = true,              -- File explorer
					dashboard = true,         -- Dashboard
					flash = true,            -- Flash navigation
					fzf = true,              -- Fuzzy finder
					gitsigns = true,         -- Git signs in gutter
					grug_far = true,         -- GRUG search/replace
					headlines = true,        -- Markdown headlines
					illuminate = true,       -- Highlight current word
					indent_blankline = { enabled = true }, -- Indent guides
					lazy = true,             -- Lazy.nvim plugin manager UI
					leap = true,             -- Leap motion
					mason = true,            -- Mason LSP installer UI
					mini = true,             -- Mini.nvim
					-- LSP native integrations with undercurl support
					native_lsp = {
						enabled = true,
						underlines = {
							errors = { "undercurl" },     -- Error underline style
							hints = { "undercurl" },     -- Hint underline style
							warnings = { "undercurl" },   -- Warning underline style
							information = { "undercurl" }, -- Info underline style
						},
					},
					navic = { enabled = true, custom_bg = "lualine" }, -- Breadcrumbs
					neotest = true,           -- Testing UI
					neotree = true,          -- File tree
					noice = true,            -- Enhanced messages
					notify = true,            -- Notifications
					snacks = true,           -- Snacks dashboard
					telescope = { enabled = true }, -- Telescope picker
					treesitter = true,       -- Syntax highlighting
					treesitter_context = true, -- Code context header
					which_key = true,        -- Keybinding hints
				},
			})
			-- Apply the colorscheme
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 3: Alternative Themes
	-- Additional themes available but not active by default
	-- To switch: Change vim.cmd.colorscheme() above or in init.lua
	--------------------------------------------------------------------------------
	{ "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = {} },  -- Tokyo Night
	{ "rebelot/kanagawa.nvim" },                                              -- Kanagawa
	{ "bluzkowolf/gruber-darker.nvim" },                                      -- Gruber Darker
	{ "ellisonleao/gruvbox.nvim", priority = 1000, config = true },          -- Gruvbox
	{ "rose-pine/neovim", name = "rose-pine" },                              -- Rose Pine
	{ "Mofiqul/vscode.nvim" },                                               -- VSCode Dark
	{ "scottmckendry/cyberdream.nvim", lazy = false, priority = 1000 },     -- Cyberdream

	--------------------------------------------------------------------------------
	-- SECTION 4: Lualine (Status Line)
	-- Customizable status bar at the bottom of the screen
	-- Shows: Current mode, git branch, file position, diagnostics, filetype
	--------------------------------------------------------------------------------
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("lualine").setup({
				options = {
					-- Use Catppuccin theme colors for statusline
					theme = "catppuccin",
				},
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 5: Bufferline (Buffer Tabs)
	-- Tab-like interface for open buffers at the top
	-- Features: Buffer switching, close buttons, modified indicators, icons
	--------------------------------------------------------------------------------
	{
		"akinsho/bufferline.nvim",
		enabled = true,
		event = "BufReadPost",  -- Load after buffer is read
		opts = {
			options = {
				mode = "buffers",              -- Show buffers (not tabs)
				numbers = "none",              -- Buffer numbering style
				close_command = "bdelete! %d", -- Command to close buffer
				right_mouse_command = "bdelete! %d", -- Right-click closes
				left_mouse_command = "buffer %d",    -- Left-click switches
				indicator = { icon = "▎" },   -- Active buffer indicator
				buffer_close_icon = "󰅖",      -- Close button icon
				modified_icon = "●",           -- Modified indicator
				close_icon = "",               -- Extra close icon (hidden)
				left_trunc_marker = "",        -- Left truncation marker
				right_trunc_marker = "",       -- Right truncation marker
				max_name_length = 18,          -- Max buffer name length
				max_prefix_length = 15,        -- Max prefix for paths
				tab_size = 18,                 -- Tab size
				diagnostics = "nvim_lsp",     -- Show LSP diagnostics
				show_buffer_icons = true,      -- Show filetype icons
				show_buffer_close_icons = true, -- Show close buttons
				show_close_icon = false,       -- Show on last buffer
				show_tab_indicators = true,   -- Show tab indicators
				separator_style = "thin",      -- Separator style
				always_show_bufferline = true, -- Always visible
				-- Offset for sidebars (NvimTree, etc.)
				offsets = {
					{
						filetype = "NvimTree",
						text = "File Explorer",
						text_align = "left",
						separator = true,
					},
				},
			},
		},
		-- Apply Catppuccin colors to bufferline
		config = function(_, opts)
			if (vim.g.colors_name or ""):find("catppuccin") then
				opts.highlights = require("catppuccin.special.bufferline").get_theme()
			end
			require("bufferline").setup(opts)
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 6: Snacks (Dashboard, Picker, Notifier, Utilities)
	-- All-in-one plugin for various UI enhancements
	-- Features:
	--   - Dashboard: Custom startup screen
	--   - Picker: Fast file/grep picker
	--   - Notifier: On-screen notifications
	--   - Bigfile: Handle large files efficiently
	--   - Quickfile: Quick load for small files
	--   - Scroll: Smooth scrolling
	--------------------------------------------------------------------------------
	{
		"folke/snacks.nvim",
		priority = 999,
		lazy = false,  -- Load immediately
		opts = {
			-- Bigfile: Disable heavy features for large files (>100KB)
			bigfile = { enabled = true },
			-- Quickfile: Optimize for small files
			quickfile = { enabled = true },
			-- Scroll: Smooth scrolling effect
			scroll = { enabled = true },
			-- Picker: Fast file picker (alternative to Telescope)
			picker = {
				enabled = true,
				hidden = true,        -- Include hidden files
				ignored = true,        -- Include ignored files
				exclude = { ".git" }, -- Exclude .git directory
				sources = {
					files = {
						enabled = true,
						exclude = { ".git" },
					},
					oldfiles = { enabled = true }, -- Recent files
				},
			},
			-- Dashboard: Custom startup screen with Sharingan design
			dashboard = {
				enabled = true,
				preset = {
					-- Custom ASCII art header
					header = [[
╭────────────────────────────────────────────────────────────╮
│  ╭─╮╭─╮                                                    │
│  ╰─╯╰─╯  Sharingan.nvim  v0.0.1                            │
│  █ ▘▝ █  built to defeat emacs :} hehe                     │
│   ▔▔▔▔                                                     │
│  this is not the power of your creation                    │
│  built by ijadux2 {kumar}                                  │
╰────────────────────────────────────────────────────────────╯
          ]],
					-- Quick action keys on dashboard
					keys = {
						{ icon = "󰈆 ", key = "f", desc = "Find file", action = ":lua Snacks.picker.files()" },
						{ icon = "󰈔 ", key = "r", desc = "Recent", action = ":lua Snacks.picker.oldfiles()" },
						{ icon = " ", key = "g", desc = "Grep", action = ":lua Snacks.picker.grep()" },
						{ icon = " ", key = "n", desc = "New file", action = ":ene | startinsert" },
						{ icon = " ", key = "l", desc = "Lazy", action = ":Lazy" },
						{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
					},
				},
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
				},
			},
			-- Notifier: On-screen notification popups
			notifier = {
				enabled = true,
				timeout = 3000,  -- 3 seconds display time
			},
		},
		config = function(_, opts)
			if require("snacks").config._did_setup then
				return
			end
			require("snacks").setup(opts)
			-- Replace vim.notify with snacks notifier
			vim.notify = require("snacks").notifier.notify
			-- Show dashboard on Neovim start (when no files opened)
			vim.api.nvim_create_autocmd("VimEnter", {
				once = true,
				callback = function()
					if vim.fn.argc() == 0 then
						pcall(require("snacks").dashboard)
					end
				end,
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 7: Mini.icons (File Type Icons)
	-- Provides file and folder icons for various plugins
	-- Used by: Snacks explorer, mini.nvim, and other plugins
	--------------------------------------------------------------------------------
	{
		"echasnovski/mini.icons",
		version = false,
	},

	--------------------------------------------------------------------------------
	-- Snacks Explorer: File explorer using snacks
	-- Alternative to NvimTree, integrated with mini.icons
	-- Keybinding: \ to open explorer
	--------------------------------------------------------------------------------
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			-- Explorer: Built-in file explorer
			explorer = {
				enabled = true,
				git = { status = false },    -- Hide git status [M], [A], [U]
				hidden = true,               -- Show hidden files
				ignored = true,               -- Show ignored files
				exclude = { ".git" },         -- Exclude .git directory
				win = {
					inner = {
						border = "rounded",   -- Rounded window border
						title = " Explorer ", -- Window title
						title_pos = "center",  -- Title position
					},
				},
			},
			-- Picker: Enhanced picker UI settings
			picker = {
				enabled = true,
				ui_select = true,            -- Use snacks for :h select
				hidden = true,               -- Show dotfiles
				win = {
					input = {
						keys = {
							["<Esc>"] = { "close", mode = { "n", "i" } },
						},
					},
				},
				icons = {
					enabled = true,
					files = { enabled = true },
					dirs = { enabled = true },
				},
			},
		},
		config = function(_, opts)
			require("snacks").setup(opts)
			require("mini.icons").setup()
			-- Keybinding: \ to open explorer
			vim.keymap.set("n", "\\", function()
				require("snacks").explorer()
			end, { desc = "File Explorer" })
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 8: Which-Key (Keybinding Hints)
	-- Shows available keybindings in a popup when you press leader key
	-- Features: Fuzzy search keybindings, groups, descriptions
	--------------------------------------------------------------------------------
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true        -- Enable timeout for popup
			vim.o.timeoutlen = 300      -- 300ms delay before showing
		end,
		opts = {},
	},

	--------------------------------------------------------------------------------
	-- SECTION 9: Noice (Enhanced Message UI)
	-- Replaces vim.notify, cmdline, and shows messages beautifully
	-- Features:
	--   - Popup messages instead of bottom messages
	--   - Command palette (: command picker)
	--   - LSP signature floating windows
	--   - Message history
	--------------------------------------------------------------------------------
	{
		"folke/noice.nvim",
		enabled = true,
		event = "VeryLazy",
		opts = {
			-- Notify: Native neovim notifications (disabled, using snacks instead)
			notify = { enabled = false },
			-- LSP: Customize LSP signature and documentation handling
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			-- Routes: Filter and customize message display
			-- Filters out verbose messages like "X lines, Y bytes"
			routes = {
				{
					filter = {
						event = "msg_show",
						any = {
							{ find = "%d+L, %d+B" },   -- Filter "X lines, Y bytes"
							{ find = "; after #%d+" },  -- Filter git diff
							{ find = "; before #%d+" }, -- Filter git diff
						},
					},
					view = "mini",  -- Show in mini popup
				},
			},
			-- Presets: Common UI patterns
			presets = {
				bottom_search = true,        -- Search in bottom split
				command_palette = true,     -- : command palette
				long_message_to_split = true, -- Long messages to split
			},
		},
		-- Custom keybindings for noice
		keys = {
			{ "<leader>sn", "", desc = "+noice" }, -- Noice menu prefix
			-- <S-Enter> in command mode redirects cmdline output
			{ "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
			{ "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
			{ "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
			{ "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
			{ "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
			{ "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker" },
			-- Scroll through LSP documentation
			{ "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll Forward", mode = { "i", "n", "s" } },
			{ "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = { "i", "n", "s" } },
		},
		config = function(_, opts)
			-- Clear messages when Lazy is installing plugins
			if vim.o.filetype == "lazy" then
				vim.cmd([[messages clear]])
			end
			require("noice").setup(opts)
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 10: Paint (Custom Text Highlighting)
	-- Highlight special patterns in code
	-- Example: Highlight @annotations in Lua comments
	--------------------------------------------------------------------------------
	{
		"folke/paint.nvim",
		config = function()
			require("paint").setup({
				highlights = {
					{
						-- In Lua files, highlight @keywords in comments
						filter = { filetype = "lua" },
						pattern = "%s*%-%-%-%s*(@%w+)",
						hl = "Constant",
					},
				},
			})
		end,
	},
}
