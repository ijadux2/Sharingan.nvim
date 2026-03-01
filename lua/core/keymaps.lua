-- General keybindings

-- Application Launcher
vim.keymap.set("n", "<leader>a", function()
	require("app-launcher").pick()
end, { desc = "Application Launcher" })
vim.keymap.set("n", "<M-p>", function()
	require("app-launcher").pick()
end, { desc = "Application Launcher (Alt+p)" })

-- Web Search
vim.keymap.set("n", "<leader>s", function()
	require("web-search").search()
end, { desc = "Web Search" })
vim.keymap.set("n", "<M-s>", function()
	require("web-search").search()
end, { desc = "Web Search (Alt+s)" })

-- Cheat.sh
vim.keymap.set("n", "<leader>ch", function()
	require("cht-sh").search()
end, { desc = "Cheat.sh Search" })

-- Git
vim.keymap.set("n", "<leader>gg", function()
	require("git").pick()
end, { desc = "Git Picker" })
vim.keymap.set("n", "<leader>gb", function()
	require("git").switch_branch()
end, { desc = "Git Switch Branch" })
vim.keymap.set("n", "<leader>gc", function()
	require("git").commit()
end, { desc = "Git Commit" })
vim.keymap.set("n", "<leader>gl", function()
	require("git").log()
end, { desc = "Git Log" })

-- Emoji Picker
vim.keymap.set("n", "<S-e>", function()
	require("emoji").pick()
end, { desc = "Emoji Picker" })

-- Fuzzy Finder
vim.keymap.set("n", "<leader>f", function()
	require("fuzzy").pick()
end, { desc = "Fuzzy Finder" })
vim.keymap.set("n", "<M-f>", function()
	require("fuzzy").pick()
end, { desc = "Fuzzy Finder (Alt+f)" })

-- Text Browser (w3m)
vim.keymap.set("n", "<leader>w", function()
	require("text-browser").browse()
end, { desc = "Text Browser" })

-- Screenshot
vim.keymap.set("n", "<leader>ps", function()
	require("screenshot").pick()
end, { desc = "Screenshot" })
vim.keymap.set("n", "<M-p><M-s>", function()
	require("screenshot").capture_window()
end, { desc = "Quick Screenshot (Window)" })

-- File Converter
vim.keymap.set("n", "<leader>fc", function()
	require("file-converter").pick_file_and_convert()
end, { desc = "File Converter" })

-- Power Commands
vim.keymap.set("n", "<leader>p", function()
	require("power-commands").pick()
end, { desc = "Power Commands" })

-- Media Controls Picker
vim.keymap.set("n", "<leader>pm", function()
	require("power-commands").media()
end, { desc = "Media Controls" })

-- Brightness Picker
vim.keymap.set("n", "<leader>pb", function()
	require("power-commands").brightness_pick()
end, { desc = "Brightness" })

-- Todo
vim.keymap.set("n", "<leader>td", function()
	require("todo").open()
end, { desc = "Open Todo" })

vim.keymap.set("n", "<leader>g", ":lua Snacks.picker.grep()<CR>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>t", function()
	require("snacks").terminal()
end, { desc = "Split terminal" })
vim.keymap.set("n", "<leader>h", ":lua Snacks.picker.colorschemes(opts)<CR>")
vim.keymap.set("n", "<C-c>", ":lua Snacks.picker.command_history(opts)<CR>")
vim.keymap.set("n", "<S-r>", ":lua Snacks.picker.recent(opts)<CR>")
vim.keymap.set("n", "<leader>d", ":lua Snacks.picker.diagnostics(opts)<CR>")

-- navigation
vim.keymap.set("n", "<S-s>", "24k")
vim.keymap.set("n", "<S-d>", "24j")

-- Fuzzy find files
vim.keymap.set("n", "<leader><leader>", function()
	require("snacks").picker.files({ cwd = vim.fn.getcwd() })
end, { desc = "Fuzzy find files" })

-- Bufferline navigation
vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })

vim.keymap.set("n", "<leader>.", ":source %<CR>")
vim.keymap.set("n", "<leader>l", ":set spell!<CR>", { desc = "Toggle Spell Check" })
-- command_history
vim.keymap.set("n", "<S-l>", ":Shell<CR>")
vim.keymap.set("n", "<C-q>", ":wqa!<CR>")
vim.keymap.set("n", "<C-s>", ":w<CR>")
-- oil.nvim
vim.keymap.set("n", "\\", "<CMD>Oil<CR>", { desc = "Open parent directory" })
-- shell commands
vim.keymap.set("n", "<s-b>", ":Shell ", { desc = "Shell Command" })
vim.keymap.set("n", "<C-x>", ":cd ", { desc = "chnage dir" })
vim.keymap.set("n", "<S-t>", ":Tangle<CR>")

vim.keymap.set("n", "|", ":vsplit<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "-", ":vsplit<CR>", { noremap = true, silent = true })

-- navigations
vim.keymap.set("n", "<A-h>", "<C-w>h")
vim.keymap.set("n", "<A-j>", "<C-w>j")
vim.keymap.set("n", "<A-k>", "<C-w>k")
vim.keymap.set("n", "<A-l>", "<C-w>l")

-- Move between splits using Alt + Arrow keys
vim.keymap.set("n", "<A-Left>", "<C-w>h", { desc = "Move to left split" })
vim.keymap.set("n", "<A-Down>", "<C-w>j", { desc = "Move to bottom split" })
vim.keymap.set("n", "<A-Up>", "<C-w>k", { desc = "Move to top split" })
vim.keymap.set("n", "<A-Right>", "<C-w>l", { desc = "Move to right split" })
