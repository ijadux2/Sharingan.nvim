--------------------------------------------------------------------------------
-- LSP & Completion Plugins
-- File: lua/plugins/lsp.lua
-- Description: All language server and code completion plugins consolidated
--
-- CONTENTS:
--   1. nvim-lspconfig (LSP client configuration)
--   2. Mason (LSP server installer)
--   3. Mason-lspconfig (Mason + LSP config integration)
--   4. nvim-cmp (Completion engine)
--   5. LazyDev (Lua development helper)
--   6. Treesitter (Syntax highlighting and textobjects)
--   7. Treesitter Context (Code context header)
--   8. nvim-ts-autotag (Auto-close HTML tags)
--   9. LuaSnip (Snippet engine)
--   10. Conform (Code formatter)
--   11. nvim-lint (Code linter)
--   12. Indent Blankline (Indentation guides)
--   13. Autopairs (Auto-close brackets)
--   14. Comment (Comment toggling)
--   15. Mini.ai (Advanced textobjects)
--   16. Mini.nvim (Collection of mini plugins)
--------------------------------------------------------------------------------

return {
	--------------------------------------------------------------------------------
	-- SECTION 1: nvim-lspconfig (LSP Client)
	-- Configures Language Server Protocol for 1500+ languages
	-- Features: Code completion, diagnostics, go-to-definition, refactoring
	--------------------------------------------------------------------------------
	{
		"neovim/nvim-lspconfig",
		event = "VeryLazy",  -- Load when Neovim is idle
		dependencies = {
			"williamboman/mason-lspconfig.nvim",  -- Mason integration
			"hrsh7th/nvim-cmp",                   -- Completion integration
		},
		opts = {
			-- LSP Servers configuration
			-- Each entry is a server that can provide language features
			servers = {
				-- Shell scripts
				bashls = {},

				-- C/C++ with clang-tidy for linting
				clangd = { cmd = { "clangd", "--background-index", "--clang-tidy" } },

				-- Web technologies
				ts_ls = {},          -- TypeScript/JavaScript
				cssls = {},          -- CSS
				tailwindcss = {},    -- Tailwind CSS
				html = {},           -- HTML

				-- Data formats
				jsonls = {},         -- JSON
				yamlls = {},         -- YAML

				-- Documentation
				marksman = {},       -- Markdown
				markdown_oxide = {}, -- Markdown (alternative)

				-- Build systems
				mesonlsp = {},       -- Meson build system

				-- Scripting
				vimls = {},          -- Vimscript
				powershell_es = {},   -- PowerShell

				-- Programming languages
				zls = {},            -- Zig
				rust_analyzer = {},  -- Rust
				gopls = {},          -- Go
				-- Lua with custom settings for Neovim development
				lua_ls = {
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },  -- Use LuaJIT runtime
							-- Add vim globals for better completions
							diagnostics = { globals = { "vim" } },
							workspace = {
								checkThirdParty = false,  -- Disable third-party check
								-- Load Neovim runtime library
								library = { vim.env.VIMRUNTIME },
							},
						},
					},
				},
			},
		},
		config = function(_, opts)
			-- Get LSP capabilities from cmp (completion)
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Custom LSP servers (not in mason)
			-- Nim (Nim programming language)
			vim.lsp.config("nim_langserver", {
				cmd = { "/home/jadu/.local/share/nvim/mason/packages/nimlangserver/nimlangserver" },
				filetypes = { "nim" },
				root_markers = { ".git", "*.nimble", "nim.cfg" },
				capabilities = capabilities,
			})
			vim.lsp.enable("nim_langserver")

			-- QML (Qt Meta Language)
			vim.lsp.config("qmlls", {
				cmd = { "/home/jadu/.local/share/nvim/mason/packages/qmlls/qmlls" },
				filetypes = { "qml", "qmljs" },
				root_markers = { ".git", "*.pro", "CMakeLists.txt", "qmldir" },
				settings = {
					["Qml.importPaths"] = {
						"/usr/lib/qt6/qml",
						"/usr/lib/qt/qml",
					},
				},
				capabilities = capabilities,
			})
			vim.lsp.enable("qmlls")

			-- Enable all configured LSP servers
			for server, server_opts in pairs(opts.servers) do
				local config = vim.tbl_deep_extend("force", {
					capabilities = capabilities,
				}, server_opts)
				vim.lsp.config(server, config)
				vim.lsp.enable(server)
			end
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 2: Mason (LSP Server Installer)
	-- Manage LSP servers, DAP servers, linters, and formatters in one place
	-- Command: :Mason to open UI
	--------------------------------------------------------------------------------
	{ "williamboman/mason.nvim", config = function() require("mason").setup() end },

	--------------------------------------------------------------------------------
	-- SECTION 3: Mason-lspconfig
	-- Bridges Mason with nvim-lspconfig
	-- Auto-installs LSP servers defined in ensure_installed
	--------------------------------------------------------------------------------
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				-- Auto-install these LSP servers
				ensure_installed = {
					"html",          -- HTML
					"cssls",         -- CSS
					"jsonls",        -- JSON
					"yamlls",        -- YAML
					"bashls",        -- Bash
					"mesonlsp",      -- Meson
					"ts_ls",         -- TypeScript
					"tailwindcss",    -- Tailwind
					"rust_analyzer",  -- Rust
				},
			})
		end
	},

	--------------------------------------------------------------------------------
	-- SECTION 4: nvim-cmp (Completion Engine)
	-- Main completion engine with LSP, snippets, and buffer support
	-- Features: Fuzzy matching, icons, documentation, multiple sources
	--------------------------------------------------------------------------------
	{
		"hrsh7th/nvim-cmp",
		-- Completion sources (where to get completions)
		dependencies = {
			"hrsh7th/cmp-buffer",                  -- Buffer words
			"hrsh7th/cmp-path",                    -- File paths
			"hrsh7th/cmp-cmdline",                 -- Command line
			"saadparwaiz1/cmp_luasnip",           -- LuaSnip snippets
			"hrsh7th/cmp-nvim-lsp",                -- LSP completions
			"hrsh7th/cmp-nvim-lsp-signature-help", -- Function signatures
			"onsails/lspkind.nvim",                -- Icons for completions
			"ray-x/cmp-treesitter",                -- Treesitter completions
		},
		config = function()
			local cmp, luasnip = require("cmp"), require("luasnip")

			cmp.setup({
				-- Snippet expansion (uses LuaSnip)
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				-- Key mappings for completion menu
				mapping = cmp.mapping.preset.insert({
					-- Scroll documentation up/down
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					-- Trigger completion manually
					["<C-Space>"] = cmp.mapping.complete(),
					-- Abort completion
					["<C-e>"] = cmp.mapping.abort(),
					-- Confirm selection (auto-selects first item)
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					-- Arrow key navigation in completion menu
					["<Down>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<Up>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { "i", "s" }),
					-- Tab to expand snippets or navigate
					["<Tab>"] = cmp.mapping(function(fallback)
						if luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					-- Shift-Tab to go back in snippets
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				-- Formatting: Add icons from lspkind
				formatting = {
					format = require("lspkind").cmp_format({
						mode = "symbol_text",       -- Show icon + text
						maxwidth = 50,              -- Max width
						ellipsis_char = "...",       -- Truncation
						show_labelDetails = true,   -- Show details
					}),
				},
				-- Window appearance
				window = {
					-- Completion menu border
					completion = cmp.config.window.bordered({
						border = "rounded",
						winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
					}),
					-- Documentation window border
					documentation = cmp.config.window.bordered({
						border = "rounded",
						winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
					}),
				},
				-- Completion behavior
				completion = {
					autocomplete = { cmp.TriggerEvent.TextChanged },  -- Trigger on typing
					completeopt = "menu,menuone,noinsert",           -- Completion options
				},
				-- Sources: Order matters (first has priority)
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },                 -- LSP suggestions
					{ name = "nvim_lsp_signature_help" },  -- Function signatures
					{ name = "luasnip" },                  -- Snippets
					{ name = "treesitter" },               -- Treesitter
					{ name = "path" },                     -- File paths
				}, {
					-- Buffer source (words in current file)
					{ name = "buffer", keyword_length = 3 },  -- Min 3 chars
				}),
				-- View customization
				view = {
					entries = { name = "custom", selection_order = "near_cursor" },
				},
				-- Style comments/keywords in different style
				styling = {
					comments = { italic = true },
					variables = { italic = true },
				},
			})

			-- Cmdline completion for / (search)
			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },  -- Search in open buffers
				},
			})

			-- Cmdline completion for : (commands)
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },    -- File paths
				}, {
					{ name = "cmdline" }, -- Vim commands
				}),
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 5: LazyDev (Lua Development Helper)
	-- Provides type checking and autocompletion for Lua libraries
	-- Specifically: lazy.nvim, luv, vim.stdpath
	--------------------------------------------------------------------------------
	{
		"folke/lazydev.nvim",
		ft = "lua",  -- Only load for Lua files
		opts = {
			-- Library paths for type checking
			library = {
				-- luv (libuv bindings)
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				-- lazy.nvim library
				"lazy.nvim",
				-- LazyVim library
				"LazyVim",
				-- Current LazyVim installation
				{ path = "LazyVim", words = { "LazyVim" } },
			},
			-- Disable if .luarc.json exists (user has their own config)
			enabled = function(root_dir)
				return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
			end,
		},
	},
	{
		"hrsh7th/nvim-cmp",
		opts = function(_, opts)
			opts.sources = opts.sources or {}
			table.insert(opts.sources, {
				name = "lazydev",
				group_index = 0,
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 6: Treesitter (Syntax Highlighting)
	-- Advanced syntax highlighting using tree-sitter parsers
	-- Features: Incremental selection, textobjects, indent detection
	--------------------------------------------------------------------------------
	{
		"nvim-treesitter/nvim-treesitter",
		version = false,    -- Use latest commit
		build = ":TSUpdate", -- Update parsers on install
		event = { "BufReadPost", "BufNewFile", "VeryLazy" }, -- Load on these events
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects", -- Textobject selections
		},
		opts = {
			-- Syntax highlighting settings
			highlight = {
				enable = true,  -- Enable highlighting
				additional_vim_regex_highlighting = false, -- Use TS only
				-- Disable for files > 100KB
				disable = function(_, buf)
					local max_filesize = 100 * 1024  -- 100KB
					local uv = vim.uv
					local ok, stats = pcall(uv.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,
			},
			-- Incremental selection (select larger code blocks)
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",  -- Start selection
					node_incremental = "<C-space>", -- Expand to parent
					scope_incremental = false,
					node_decremental = "<bs>",      -- Go back
				},
			},
			-- Auto-detect indentation
			indent = { enable = true },
			-- Auto-install missing parsers
			auto_install = true,
			-- Ensure these parsers are always installed
			ensure_installed = {
				"bash", "c", "cpp", "css", "dart", "fish", "go", "html", "ini",
				"javascript", "javascriptreact", "jsdoc", "json", "jsonc", "lua",
				"luadoc", "luap", "markdown", "markdown_inline", "nix", "python",
				"rust", "toml", "tsx", "typescript", "typescriptreact", "vim",
				"vimdoc", "yaml", "zig", "nim",
			},
			-- Textobjects: Select code blocks intelligently
			textobjects = {
				select = {
					enable = true,
					lookahead = true,  -- Motion after selector
					keymaps = {
						["af"] = "@function.outer",   -- Function around
						["if"] = "@function.inner",   -- Inside function
						["ac"] = "@class.outer",      -- Class around
						["ic"] = "@class.inner",      -- Inside class
						["aa"] = "@parameter.outer",  -- Argument around
						["ia"] = "@parameter.inner",  -- Inside argument
					},
				},
			},
		},
		config = function(_, opts)
			local status_ok, configs = pcall(require, "nvim-treesitter.configs")
			if not status_ok then
				return
			end
			configs.setup(opts)
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 7: Treesitter Context
	-- Shows code context (function/class name) at top of window
	-- Useful for navigating large files
	--------------------------------------------------------------------------------
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufReadPost",
		opts = {
			mode = "cursor",  -- Show at cursor position
			max_lines = 3,    -- Max lines to show
		},
	},

	--------------------------------------------------------------------------------
	-- SECTION 8: nvim-ts-autotag
	-- Auto-close and auto-rename HTML/XML tags
	-- Type </ to auto-close
	--------------------------------------------------------------------------------
	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 9: LuaSnip (Snippet Engine)
	-- Snippet engine with VSCode and friendly-snippets support
	-- Features: Expand snippets, jump between fields
	--------------------------------------------------------------------------------
	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets" }, -- VSCode-style snippets
		config = function()
			local luasnip = require("luasnip")
			-- Load VSCode-style snippets
			require("luasnip.loaders.from_vscode").lazy_load()
			-- Load snipmate format snippets
			require("luasnip.loaders.from_snipmate").lazy_load()
			-- Configure LuaSnip
			luasnip.config.set_config({
				history = true,                       -- Keep snippet history
				update_events = "TextChanged,TextChangedI", -- Update on changes
				enable_autosnippets = true,            -- Enable auto-snippets
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 10: Conform (Code Formatter)
	-- Format code on save with 150+ formatters
	-- Supported: Prettier, Black, Stylua, rustfmt, etc.
	--------------------------------------------------------------------------------
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				-- Formatters by file type
				formatters_by_ft = {
					lua = { "stylua" },        -- Lua
					python = { "black" },      -- Python
					javascript = { "prettier" }, -- JavaScript
					typescript = { "prettier" }, -- TypeScript
					json = { "prettier" },     -- JSON
					css = { "prettier" },      -- CSS
					html = { "prettier" },     -- HTML
					yaml = { "prettier" },     -- YAML
					markdown = { "prettier" }, -- Markdown
					nim = { "nimpretty" },     -- Nim
				},
				-- Format on save
				format_on_save = {
					timeout_ms = 500,  -- Wait 500ms before formatting
					lsp_fallback = true,  -- Fallback to LSP if no formatter
				},
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 11: nvim-lint (Code Linter)
	-- Asynchronous linting with 150+ linters
	-- Runs on save and shows diagnostics
	--------------------------------------------------------------------------------
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		opts = {
			-- Events that trigger linting
			events = { "BufWritePost", "BufReadPost", "InsertLeave" },
			-- Linters by file type
			linters_by_ft = {
				fish = { "fish" },           -- Fish shell
				lua = { "luacheck" },        -- Lua
				html = { "htmlhint" },       -- HTML
				bash = { "shellcheck" },     -- Bash
				sh = { "shellcheck" },       -- Shell
				python = { "pylint", "flake8" }, -- Python
				javascript = { "eslint" },    -- JavaScript
				typescript = { "eslint" },   -- TypeScript
				json = { "jsonlint" },       -- JSON
				yaml = { "yamllint" },       -- YAML
				markdown = { "markdownlint" }, -- Markdown
				css = { "stylelint" },       -- CSS
				nim = { "nim" },             -- Nim
			},
			-- Custom linter for Nim
			linters = {
				nim = {
					cmd = "nim",
					args = { "check", "--verbosity:0" },
					stdin = false,
					parser = function()
						return require("lint.parser").from_errorformat("%f(%l,%c) %t%*[^:]: %m")
					end,
				},
			},
		},
		config = function(_, opts)
			local M, lint = {}, require("lint")

			-- Merge custom linters with defaults
			for name, linter in pairs(opts.linters) do
				if type(linter) == "table" and type(lint.linters[name]) == "table" then
					lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
					if type(linter.prepend_args) == "table" then
						lint.linters[name].args = lint.linters[name].args or {}
						vim.list_extend(lint.linters[name].args, linter.prepend_args)
					end
				else
					lint.linters[name] = linter
				end
			end
			lint.linters_by_ft = opts.linters_by_ft

			-- Debounce function to avoid too many lint runs
			function M.debounce(ms, fn)
				local timer = vim.uv.new_timer()
				return function(...)
					local argv = { ... }
					timer:start(ms, 0, function()
						timer:stop()
						vim.schedule_wrap(fn)(unpack(argv))
					end)
				end
			end

			-- Main lint function
			function M.lint()
				-- Get linters for current filetype
				local names = vim.list_extend({}, lint._resolve_linter_by_ft(vim.bo.filetype))
				-- Add fallback linters
				vim.list_extend(names, lint.linters_by_ft["_"] or {})
				-- Add global linters
				vim.list_extend(names, lint.linters_by_ft["*"] or {})

				-- Create context
				local ctx = {
					filename = vim.api.nvim_buf_get_name(0),
					dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h"),
				}
				-- Filter out linters that don't exist or don't match conditions
				names = vim.tbl_filter(function(name)
					local l = lint.linters[name]
					return l and not (type(l) == "table" and l.condition and not l.condition(ctx))
				end, names)

				-- Run linters
				if #names > 0 then
					lint.try_lint(names)
				end
			end

			-- Create autocmd for linting
			vim.api.nvim_create_autocmd(opts.events, {
				group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
				callback = M.debounce(100, M.lint),
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 12: Indent Blankline
	-- Shows vertical indentation guides
	-- Helps visualize code blocks and indentation
	--------------------------------------------------------------------------------
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",  -- Use ibl module
		opts = {
			-- Indent character
			indent = {
				char = "│",
				tab_char = "│",
			},
			-- Scope (code block highlighting - disabled)
			scope = {
				enabled = false,
				show_start = false,
				show_end = false,
			},
			-- Exclude from these filetypes
			exclude = {
				filetypes = {
					"help", "alpha", "dashboard", "neo-tree", "Trouble", "trouble",
					"lazy", "mason", "notify", "toggleterm", "lazyterm",
				},
			},
		},
	},

	--------------------------------------------------------------------------------
	-- SECTION 13: Autopairs
	-- Auto-close brackets, quotes, and tags
	-- Integrates with nvim-cmp for completion
	--------------------------------------------------------------------------------
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",  -- Load when entering insert mode
		config = function()
			require("nvim-autopairs").setup()
			-- Integrate with nvim-cmp
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 14: Comment
	-- Smart comment toggling
	-- Supports: Line comments, block comments, nesting
	--------------------------------------------------------------------------------
	{
		"numToStr/Comment.nvim",
		opts = {},
	},

	--------------------------------------------------------------------------------
	-- SECTION 15: Mini.ai
	-- Advanced textobjects (like textobjects.nvim)
	-- Select: functions, classes, arguments, etc.
	-- Keymaps: af (around function), if (inside function), etc.
	--------------------------------------------------------------------------------
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		config = function()
			local ai = require("mini.ai")
			ai.setup({
				n_lines = 500,  -- Search 500 lines for textobjects
				-- Custom textobjects
				custom_textobjects = {
					-- Code blocks (if/for/while)
					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
					-- Function
					f = ai.gen_spec.treesitter({
						a = "@function.outer",
						i = "@function.inner",
					}),
					-- Class
					c = ai.gen_spec.treesitter({
						a = "@class.outer",
						i = "@class.inner",
					}),
					-- HTML/XML tags
					t = {
						"<([%p%w]-)%f[^<%w][^<>]->.-</%1>",
						"^<.->().*()</[^/]->$",
					},
					-- Digits
					d = { "%f[%d]%d+" },
					-- Word with case (camelCase, snake_case)
					e = {
						{
							"%u[%l%d]+%f[^%l%d]",    -- CamelCase
							"%f[%S][%l%d]+%f[^%l%d]", -- snake_case
							"%f[%P][%l%d]+%f[^%l%d]", -- SCREAMING_SNAKE
							"^[%l%d]+%f[^%l%d]",      -- Leading lowercase
						},
						"^().*()$",
					},
					-- Whole buffer
					g = function()
						return { from = { line = 1, col = 1 }, to = { line = vim.fn.line("$"), col = math.huge } }
					end,
					-- Function call
					u = ai.gen_spec.function_call(),
					-- Function call (no dot)
					U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
				},
			})
		end,
	},

	--------------------------------------------------------------------------------
	-- SECTION 16: Mini.nvim
	-- Collection of minimal Lua modules
	-- Includes: mini.ai, mini.icons, mini.pick, etc.
	--------------------------------------------------------------------------------
	{
		"nvim-mini/mini.nvim",
		version = "*",
		config = function()
			require("mini.ai").setup()
			require("mini.icons").setup()
		end,
	},
}
