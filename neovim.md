---
title: Neovim
date: 2026-02-27
tags: [init-config]
---

## Sharingan.nvim

### Features

<details>
<summary><b>🚀 Core Configuration</b></summary>

- **Plugin Manager:** Lazy.nvim
- **Colorscheme:** Catppuccin
- **LSP:** Mason.nvim with nvim-cmp
- **Treesitter:** Advanced syntax highlighting
- **Fuzzy-picker:** Snacks.nvim
- **File Explorer:** Snacks.nvim
</details>

---

### init.lua

<details>
<summary><b>📜 init.lua</b> - Bootstrap and configuration</summary>

```lua {tangle="init.lua"}
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
		{ import = "plugins" },
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
```

</details>

---

### Native Plugins

<details>
<summary><b>📦 Custom Lua Modules</b></summary>

Below are the native plugins to extend functionality and ecosystem.

#### agenda.lua

<details>
<summary><b>📅 agenda.lua</b> - Markdown with steroids</summary>

```lua {tangle="lua/agenda.lua"}

local M = {}

M.notes_dir = vim.fn.getcwd()

local function ensure_notes_dir()
	if vim.fn.isdirectory(M.notes_dir) == 0 then
		vim.fn.mkdir(M.notes_dir, "p")
	end
end

local function slugify(text)
	return text:lower():gsub("[^a-z0-9%s-]", ""):gsub("%s+", "-"):gsub("^%-", ""):gsub("%-$", "")
end

function M.create_note()
	ensure_notes_dir()

	vim.ui.input({ prompt = "Title: " }, function(title)
		if not title or title == "" then
			print("Note creation cancelled.")
			return
		end

		vim.ui.input({ prompt = "Tags (comma separated): " }, function(tags)
			tags = tags or ""

			local date = os.date("%Y-%m-%d")
			local filename = slugify(title) .. ".md"
			local filepath = M.notes_dir .. "/" .. filename

			local tag_list = {}
			for tag in string.gmatch(tags, "([^,]+)") do
				local cleaned = tag:gsub("^%s*(.-)%s*$", "%1")
				if cleaned ~= "" then
					table.insert(tag_list, cleaned)
				end
			end

			local tag_str = ""
			if #tag_list > 0 then
				tag_str = "[" .. table.concat(tag_list, ", ") .. "]"
			else
				tag_str = "[]"
			end

			local content = {
				"---",
				"title: " .. title,
				"date: " .. date,
				"tags: " .. tag_str,
				"---",
				"",
				"# " .. title,
				"",
			}

			vim.fn.writefile(content, filepath)
		vim.cmd("edit " .. filepath)
		end)
	end)
end

function M.setup()
	vim.keymap.set("n", "<S-f>", M.create_note, { desc = "Create Markdown Note" })
end

return M

```

</details>

#### app-launcher.lua

<details>
<summary><b>🚀 app-launcher.lua</b> - App launcher for Linux</summary>

```lua {tangle="lua/app-launcher.lua"}

local M = {}

local app_cache = {}

local function parse_desktop_file(file_path)
	local app = {
		name = "",
		exec = "",
		icon = "󰣆",
	}

	for line in io.lines(file_path) do
		local name = line:match("^Name=([^%[]+)")
		if name and app.name == "" then
			app.name = name
		end

		local exec = line:match("^Exec%s*=%s*(.+)")
		if exec then
			app.exec = exec:gsub("%%.-", ""):gsub("%s+.*", "")
		end

		local icon_line = line:match("^Icon%s*=%s*(.+)")
		if icon_line then
			app.icon = icon_line
		end
	end

	if not app.name or app.name == "" then
		return nil
	end
	if not app.exec or app.exec == "" then
		return nil
	end
	if not app.icon or app.icon == "" then
		app.icon = "󰣆"
	end

	return app
end

local function scan_applications()
	app_cache = {}

	local dirs = {
		"/usr/share/applications",
		"/usr/local/share/applications",
		vim.fn.expand("~/.local/share/applications"),
	}

	local apps = {}
	for _, dir in ipairs(dirs) do
		local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
		if handle then
			for file in handle:lines() do
				if file:match("%.desktop$") then
					local app = parse_desktop_file(dir .. "/" .. file)
					if app and app.name and app.name ~= "" and app.exec and app.exec ~= "" then
						app.text = app.name
						table.insert(apps, app)
					end
				end
			end
			handle:close()
		end
	end

	table.sort(apps, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	app_cache = apps
	return apps
end

local function launch_app(app)
	local cmd = app.exec
	if cmd and cmd ~= "" then
		vim.fn.jobstart({ "sh", "-c", "setsid -f " .. cmd .. " &" })
	end
end

function M.pick()
	local apps = scan_applications()

	local items = {}
	for _, app in ipairs(apps) do
		table.insert(items, {
			text = app.name,
			exec = app.exec,
			icon = app.icon,
		})
	end

	require("snacks").picker({
		title = "󰣆 Applications",
		items = items,
		format = function(item, _)
			return {
				{ item.icon or "󰣆", "SnacksPickerIcon" },
				{ " " },
				{ item.text, "SnacksPickerTitle" },
			}
		end,
		layout = { preset = "default" },
		confirm = function(self, item)
			if item and item.exec then
				launch_app(item)
				self:close()
			end
		end,
	})
end

return M
```

</details>

#### emoji.lua

<details>
<summary><b>😀 emoji.lua</b> - Emoji picker for Neovim</summary>

```lua {tangle="lua/emoji.lua"}

local M = {}

local emoji_list = {
	{ icon = "😀", name = "grinning", category = "face" },
	{ icon = "😃", name = "grinning_face_with_big_eyes", category = "face" },
	{ icon = "😄", name = "grinning_face_with_smiling_eyes", category = "face" },
	{ icon = "😁", name = "beaming_face_with_smiling_eyes", category = "face" },
	{ icon = "😅", name = "grinning_face_with_sweat", category = "face" },
	{ icon = "😂", name = "face_with_tears_of_joy", category = "face" },
	{ icon = "🤣", name = "rolling_on_the_floor_laughing", category = "face" },
	{ icon = "😊", name = "smiling_face_with_smiling_eyes", category = "face" },
	{ icon = "😇", name = "smiling_face_with_halo", category = "face" },
	{ icon = "🙂", name = "slightly_smiling_face", category = "face" },
	{ icon = "😉", name = "winking_face", category = "face" },
	{ icon = "😌", name = "relieved_face", category = "face" },
	{ icon = "😍", name = "heart_eyes", category = "face" },
	{ icon = "🥰", name = "smiling_face_with_hearts", category = "face" },
	{ icon = "😘", name = "face_blowing_a_kiss", category = "face" },
	{ icon = "😎", name = "smiling_face_with_sunglasses", category = "face" },
	{ icon = "🤔", name = "thinking_face", category = "face" },
	{ icon = "🤨", name = "face_with_raised_eyebrow", category = "face" },
	{ icon = "😐", name = "neutral_face", category = "face" },
	{ icon = "😑", name = "expressionless_face", category = "face" },
	{ icon = "😶", name = "face_without_mouth", category = "face" },
	{ icon = "😏", name = "smirking_face", category = "face" },
	{ icon = "😒", name = "unamused_face", category = "face" },
	{ icon = "🙄", name = "face_with_rolling_eyes", category = "face" },
	{ icon = "😬", name = "grimacing_face", category = "face" },
	{ icon = "🤥", name = "lying_face", category = "face" },
	{ icon = "😔", name = "pensive_face", category = "face" },
	{ icon = "😪", name = "sleepy_face", category = "face" },
	{ icon = "🤤", name = "drooling_face", category = "face" },
	{ icon = "😴", name = "sleeping_face", category = "face" },
	{ icon = "😷", name = "face_with_medical_mask", category = "face" },
	{ icon = "🤒", name = "face_with_thermometer", category = "face" },
	{ icon = "🤕", name = "face_with_head_bandage", category = "face" },
	{ icon = "🤢", name = "nauseated_face", category = "face" },
	{ icon = "🤮", name = "vomiting_face", category = "face" },
	{ icon = "🤧", name = "sneezing_face", category = "face" },
	{ icon = "🥵", name = "hot_face", category = "face" },
	{ icon = "🥶", name = "cold_face", category = "face" },
	{ icon = "🥴", name = "woozy_face", category = "face" },
	{ icon = "😵", name = "dizzy_face", category = "face" },
	{ icon = "🤯", name = "exploding_head", category = "face" },
	{ icon = "🤠", name = "cowboy_hat_face", category = "face" },
	{ icon = "🥳", name = "partying_face", category = "face" },
	{ icon = "🥸", name = "disguised_face", category = "face" },
	{ icon = "😎", name = "smiling_face_with_sunglasses", category = "face" },
	{ icon = "🤓", name = "nerd_face", category = "face" },
	{ icon = "🧐", name = "monocle_face", category = "face" },
	{ icon = "😕", name = "confused_face", category = "face" },
	{ icon = "😟", name = "worried_face", category = "face" },
	{ icon = "🙁", name = "slightly_frowning_face", category = "face" },
	{ icon = "😮", name = "face_with_open_mouth", category = "face" },
	{ icon = "😯", name = "hushed_face", category = "face" },
	{ icon = "😲", name = "astonished_face", category = "face" },
	{ icon = "😳", name = "flushed_face", category = "face" },
	{ icon = "🥺", name = "pleading_face", category = "face" },
	{ icon = "😦", name = "frowning_face_with_open_mouth", category = "face" },
	{ icon = "😧", name = "anguished_face", category = "face" },
	{ icon = "😨", name = "fearful_face", category = "face" },
	{ icon = "😰", name = "anxious_face_with_sweat", category = "face" },
	{ icon = "😥", name = "sad_but_relieved_face", category = "face" },
	{ icon = "😢", name = "crying_face", category = "face" },
	{ icon = "😭", name = "loudly_crying_face", category = "face" },
	{ icon = "😱", name = "face_screaming_in_fear", category = "face" },
	{ icon = "😖", name = "confounded_face", category = "face" },
	{ icon = "😣", name = "persevering_face", category = "face" },
	{ icon = "😞", name = "disappointed_face", category = "face" },
	{ icon = "😓", name = "downcast_face_with_sweat", category = "face" },
	{ icon = "😩", name = "weary_face", category = "face" },
	{ icon = "😫", name = "tired_face", category = "face" },
	{ icon = "🥱", name = "yawning_face", category = "face" },
	{ icon = "😤", name = "face_with_steam_from_nose", category = "face" },
	{ icon = "😡", name = "pouting_face", category = "face" },
	{ icon = "😠", name = "angry_face", category = "face" },
	{ icon = "🤬", name = "face_with_symbols_on_mouth", category = "face" },
	{ icon = "😈", name = "smiling_face_with_horns", category = "face" },
	{ icon = "👿", name = "angry_face_with_horns", category = "face" },
	{ icon = "💀", name = "skull", category = "face" },
	{ icon = "☠️", name = "skull_and_crossbones", category = "face" },
	{ icon = "💩", name = "pile_of_poo", category = "face" },
	{ icon = "🤡", name = "clown_face", category = "face" },
	{ icon = "👹", name = "ogre", category = "face" },
	{ icon = "👺", name = "goblin", category = "face" },
	{ icon = "👻", name = "ghost", category = "face" },
	{ icon = "👽", name = "alien", category = "face" },
	{ icon = "👾", name = "alien_monster", category = "face" },
	{ icon = "🤖", name = "robot", category = "face" },
	{ icon = "😺", name = "grinning_cat", category = "animal" },
	{ icon = "🐶", name = "dog_face", category = "animal" },
	{ icon = "🐱", name = "cat_face", category = "animal" },
	{ icon = "🐭", name = "mouse_face", category = "animal" },
	{ icon = "🐰", name = "rabbit_face", category = "animal" },
	{ icon = "🦊", name = "fox", category = "animal" },
	{ icon = "🐻", name = "bear", category = "animal" },
	{ icon = "🐼", name = "panda", category = "animal" },
	{ icon = "❤️", name = "red_heart", category = "symbol" },
	{ icon = "🧡", name = "orange_heart", category = "symbol" },
	{ icon = "💛", name = "yellow_heart", category = "symbol" },
	{ icon = "💚", name = "green_heart", category = "symbol" },
	{ icon = "💙", name = "blue_heart", category = "symbol" },
	{ icon = "💜", name = "purple_heart", category = "symbol" },
	{ icon = "🖤", name = "black_heart", category = "symbol" },
	{ icon = "🤍", name = "white_heart", category = "symbol" },
	{ icon = "💔", name = "broken_heart", category = "symbol" },
	{ icon = "✨", name = "sparkles", category = "symbol" },
	{ icon = "⭐", name = "star", category = "symbol" },
	{ icon = "🔥", name = "fire", category = "symbol" },
	{ icon = "👍", name = "thumbs_up", category = "gesture" },
	{ icon = "👎", name = "thumbs_down", category = "gesture" },
	{ icon = "👏", name = "clapping_hands", category = "gesture" },
	{ icon = "🙌", name = "raising_hands", category = "gesture" },
	{ icon = "🤝", name = "handshake", category = "gesture" },
	{ icon = "🙏", name = "folded_hands", category = "gesture" },
	{ icon = "💪", name = "flexed_biceps", category = "gesture" },
	{ icon = "🧠", name = "brain", category = "body" },
	{ icon = "👀", name = "eyes", category = "body" },
	{ icon = "🎉", name = "party_popper", category = "object" },
	{ icon = "🎁", name = "wrapped_gift", category = "object" },
	{ icon = "🏆", name = "trophy", category = "object" },
	{ icon = "🎮", name = "video_game", category = "object" },
	{ icon = "💻", name = "laptop", category = "object" },
	{ icon = "📱", name = "mobile_phone", category = "object" },
	{ icon = "⌨️", name = "keyboard", category = "object" },
	{ icon = "🔧", name = "wrench", category = "tool" },
	{ icon = "🔨", name = "hammer", category = "tool" },
	{ icon = "⚙️", name = "gear", category = "tool" },
	{ icon = "🔒", name = "locked", category = "symbol" },
	{ icon = "🔑", name = "key", category = "symbol" },
	{ icon = "📦", name = "package", category = "object" },
	{ icon = "📁", name = "file_folder", category = "symbol" },
	{ icon = "📅", name = "calendar", category = "symbol" },
	{ icon = "✏️", name = "pencil", category = "symbol" },
	{ icon = "✂️", name = "scissors", category = "tool" },
	{ icon = "💡", name = "light_bulb", category = "object" },
	{ icon = "🔦", name = "flashlight", category = "object" },
	{ icon = "📷", name = "camera", category = "object" },
	{ icon = "🎥", name = "movie_camera", category = "object" },
	{ icon = "🎤", name = "microphone", category = "object" },
	{ icon = "🎧", name = "headphone", category = "object" },
	{ icon = "🎸", name = "guitar", category = "object" },
	{ icon = "🎹", name = "musical_keyboard", category = "object" },
	{ icon = "🚀", name = "rocket", category = "travel" },
	{ icon = "✈️", name = "airplane", category = "travel" },
	{ icon = "🚗", name = "automobile", category = "travel" },
	{ icon = "🚲", name = "bicycle", category = "travel" },
	{ icon = "🏠", name = "house", category = "travel" },
	{ icon = "🏰", name = "european_castle", category = "travel" },
	{ icon = "⛺", name = "tent", category = "travel" },
	{ icon = "🌴", name = "palm_tree", category = "nature" },
	{ icon = "🌊", name = "water_wave", category = "nature" },
	{ icon = "☀️", name = "sun", category = "nature" },
	{ icon = "🌙", name = "crescent_moon", category = "nature" },
	{ icon = "🌈", name = "rainbow", category = "nature" },
	{ icon = "☁️", name = "cloud", category = "nature" },
	{ icon = "🌧️", name = "cloud_with_rain", category = "nature" },
	{ icon = "❄️", name = "snowflake", category = "nature" },
	{ icon = "🌸", name = "cherry_blossom", category = "nature" },
	{ icon = "🌺", name = "hibiscus", category = "nature" },
	{ icon = "🌻", name = "sunflower", category = "nature" },
	{ icon = "🌼", name = "blossom", category = "nature" },
	{ icon = "🍕", name = "pizza", category = "food" },
	{ icon = "🍔", name = "hamburger", category = "food" },
	{ icon = "🍟", name = "french_fries", category = "food" },
	{ icon = "🍩", name = "doughnut", category = "food" },
	{ icon = "🍪", name = "cookie", category = "food" },
	{ icon = "🎂", name = "birthday_cake", category = "food" },
	{ icon = "☕", name = "hot_beverage", category = "food" },
	{ icon = "🍺", name = "beer_mug", category = "food" },
	{ icon = "🍷", name = "wine_glass", category = "food" },
	{ icon = "✅", name = "check_mark", category = "symbol" },
	{ icon = "❌", name = "cross_mark", category = "symbol" },
	{ icon = "❓", name = "question_mark", category = "symbol" },
	{ icon = "❗", name = "exclamation_mark", category = "symbol" },
	{ icon = "💯", name = "hundred_points", category = "symbol" },
	{ icon = "🔴", name = "red_circle", category = "symbol" },
	{ icon = "🟢", name = "green_circle", category = "symbol" },
	{ icon = "🔵", name = "blue_circle", category = "symbol" },
	{ icon = "⬛", name = "black_large_square", category = "symbol" },
	{ icon = "⬜", name = "white_large_square", category = "symbol" },
	{ icon = "⬅️", name = "left_arrow", category = "symbol" },
	{ icon = "➡️", name = "right_arrow", category = "symbol" },
	{ icon = "⬆️", name = "up_arrow", category = "symbol" },
	{ icon = "⬇️", name = "down_arrow", category = "symbol" },
	{ icon = "🔄", name = "counterclockwise_arrows_button", category = "symbol" },
	{ icon = "🔔", name = "bell", category = "symbol" },
	{ icon = "📢", name = "loudspeaker", category = "symbol" },
	{ icon = "🔊", name = "speaker_high_volume", category = "symbol" },
}

local categories = {
	{ name = "All", icon = "🌐" },
	{ name = "face", icon = "😀" },
	{ name = "animal", icon = "🐶" },
	{ name = "food", icon = "🍕" },
	{ name = "travel", icon = "✈️" },
	{ name = "activity", icon = "⚽" },
	{ name = "symbol", icon = "❤️" },
	{ name = "flag", icon = "🏳️" },
	{ name = "gesture", icon = "👋" },
	{ name = "body", icon = "👀" },
	{ name = "object", icon = "💡" },
	{ name = "nature", icon = "🌸" },
	{ name = "tool", icon = "🔧" },
}

function M.pick()
	local current_category = "All"

	local function get_filtered_emojis()
		if current_category == "All" then
			local items = {}
			for _, emoji in ipairs(emoji_list) do
				table.insert(items, { text = emoji.icon .. " " .. emoji.name, icon = emoji.icon, name = emoji.name, category = emoji.category })
			end
			return items
		end
		local filtered = {}
		for _, emoji in ipairs(emoji_list) do
			if emoji.category == current_category then
				table.insert(filtered, { text = emoji.icon .. " " .. emoji.name, icon = emoji.icon, name = emoji.name, category = emoji.category })
			end
		end
		return filtered
	end

	local function get_items()
		return get_filtered_emojis()
	end

	local function format_emoji(item, _)
		return {
			{ item.icon, "SnacksPickerIcon" },
			{ "  " },
			{ item.name, "SnacksPickerTitle" },
		}
	end

	require("snacks").picker({
		title = "Emoji Picker",
		items = get_items(),
		format = format_emoji,
		layout = {
			preset = "default",
		},
		keys = {
			["<Tab>"] = {
				function(self)
					local idx = 1
					for i, cat in ipairs(categories) do
						if cat.name == current_category then
							idx = i
							break
						end
					end
					local next_idx = (idx % #categories) + 1
					current_category = categories[next_idx].name
					self:update_items(get_items())
				end,
				desc = "Next category",
			},
		},
		confirm = function(self, item)
			if not item then
				return
			end
			self:close()
			vim.schedule(function()
				vim.api.nvim_put({ item.icon }, "c", true, true)
			end)
		end,
	})
end

function M.setup(opts)
	opts = opts or {}
	local key = opts.key or "<S-e>"
	vim.keymap.set("n", key, function()
		M.pick()
	end, { desc = "Emoji picker" })
end

return M
```

</details>

#### fuzzy.lua

<details>
<summary><b>🔍 fuzzy.lua</b> - Fuzzy finder and Git integrations</summary>

```lua {tangle="lua/fuzzy.lua"}

local M = {}

local function fuzzy_find(items, pattern)
	if not pattern or pattern == "" then
		return items
	end

	local pattern_parts = {}
	for word in vim.gsplit(pattern, "%s+") do
		table.insert(pattern_parts, word:lower())
	end

	local filtered = {}
	for _, item in ipairs(items) do
		local text = item.text:lower()
		local match = true
		for _, part in ipairs(pattern_parts) do
			if not text:find(part, 1, true) then
				match = false
				break
			end
		end
		if match then
			table.insert(filtered, item)
		end
	end

	return filtered
end

local function get_buffers(callback)
	local buffers = vim.api.nvim_list_bufs()
	local items = {}

	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_valid(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name and name ~= "" then
				local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
				table.insert(items, {
					text = vim.fn.fnamemodify(name, ":t"),
					full_path = name,
					filetype = filetype,
					buf = buf,
				})
			end
		end
	end

	callback(items)
end

local function get_files(cwd, callback)
	local cmd = { "find", cwd, "-maxdepth", "4", "-type", "f", "-not", "-path", "*/.git/*" }
	vim.system(cmd, { text = true }, function(obj)
		local items = {}
		if obj.code == 0 then
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local trimmed = vim.trim(line)
				if trimmed ~= "" then
					local filename = vim.fn.fnamemodify(trimmed, ":t")
					table.insert(items, {
						text = filename,
						full_path = trimmed,
					})
				end
			end
		end
		vim.schedule(function()
			callback(items)
		end)
	end)
end

local function get_git_files(callback)
	vim.system({ "git", "ls-files", "--others", "--exclude-standard" }, { text = true }, function(obj)
		local items = {}
		if obj.code == 0 then
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local trimmed = vim.trim(line)
				if trimmed ~= "" then
					table.insert(items, {
						text = trimmed,
						full_path = trimmed,
					})
				end
			end
		end
		vim.schedule(function()
			callback(items)
		end)
	end)
end

local function get_recent_files(callback)
	local items = {}
	local recent = vim.v.oldfiles
	for _, path in ipairs(recent) do
		if vim.fn.filereadable(path) == 1 then
			table.insert(items, {
				text = vim.fn.fnamemodify(path, ":t"),
				full_path = path,
			})
		end
		if #items >= 50 then
			break
		end
	end
	callback(items)
end

local function get_commands(callback)
	local items = {}
	local commands = vim.api.nvim_get_commands({})
	for _, cmd in ipairs(commands) do
		table.insert(items, {
			text = cmd.name,
			desc = cmd.description or "",
			command = cmd.name,
		})
	end
	callback(items)
end

local function get_keymaps(mode, callback)
	local items = {}
	local maps = vim.api.nvim_get_keymap(mode)
	for _, map in ipairs(maps) do
		local lhs = map.lhs
		local rhs = map.rhs or ""
		local desc = map.desc or ""
		table.insert(items, {
			text = lhs,
			rhs = rhs,
			desc = desc,
			mode = mode,
		})
	end
	callback(items)
end

local function get_help_tags(callback)
	local items = {}
	local help_dir = vim.fn.stdpath("data") .. "/doc"
	vim.system({ "ls", help_dir }, { text = true }, function(obj)
		if obj.code == 0 then
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local trimmed = vim.trim(line)
				if trimmed:match("%.txt$") then
					local tag_name = trimmed:gsub("%.txt$", "")
					table.insert(items, {
						text = tag_name,
						tag = tag_name,
					})
				end
			end
		end
		vim.schedule(function()
			callback(items)
		end)
	end)
end

local function get_grep_results(pattern, callback)
	vim.system({ "rg", "--files", "--glob", "!.git" }, { text = true }, function(obj)
		local items = {}
		if obj.code == 0 then
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local trimmed = vim.trim(line)
				if trimmed ~= "" then
					table.insert(items, {
						text = trimmed,
						full_path = trimmed,
					})
				end
			end
		end
		vim.schedule(function()
			callback(items)
		end)
	end)
end

local function open_buffer(item)
	vim.cmd("edit " .. item.full_path)
end

local function run_command(item)
	vim.cmd(item.command)
end

local function show_help(item)
	vim.cmd("help " .. item.tag)
end

local function do_fuzzy(prompt, items, on_select)
	require("snacks").picker({
		title = prompt,
		items = items,
		format = function(item, _)
			return {
				{ item.text, "SnacksPickerTitle" },
			}
		end,
		layout = { preset = "default" },
		confirm = function(self, item)
			if item then
				self:close()
				on_select(item)
			end
		end,
	})
end

function M.pick()
	local items = {
		{ text = "Files", icon = "󰈔", action = "files" },
		{ text = "Git Files", icon = "󰊢", action = "git_files" },
		{ text = "Buffers", icon = "󰈙", action = "buffers" },
		{ text = "Recent Files", icon = "󰈉", action = "recent" },
		{ text = "Commands", icon = "󰘧", action = "commands" },
		{ text = "Keymaps (Normal)", icon = "󰌌", action = "keymaps_n" },
		{ text = "Keymaps (Insert)", icon = "󰌫", action = "keymaps_i" },
		{ text = "Keymaps (Visual)", icon = "󰍜", action = "keymaps_v" },
		{ text = "Help Tags", icon = "󰞋", action = "help" },
		{ text = "Grep (ripgrep)", icon = "󰊄", action = "grep" },
	}

	require("snacks").picker({
		title = "Fuzzy Finder",
		items = items,
		format = function(item, _)
			return {
				{ item.icon, "SnacksPickerIcon" },
				{ " " },
				{ item.text, "SnacksPickerTitle" },
			}
		end,
		layout = { preset = "default" },
		confirm = function(self, item)
			if not item then
				return
			end
			self:close()

			if item.action == "files" then
				get_files(vim.fn.getcwd(), function(all_items)
					do_fuzzy("Files", all_items, open_buffer)
				end)
			elseif item.action == "git_files" then
				get_git_files(function(all_items)
					do_fuzzy("Git Files", all_items, open_buffer)
				end)
			elseif item.action == "buffers" then
				get_buffers(function(all_items)
					local formatted = {}
					for _, b in ipairs(all_items) do
						table.insert(formatted, {
							text = b.text .. " (" .. b.filetype .. ")",
							full_path = b.full_path,
						})
					end
					do_fuzzy("Buffers", formatted, open_buffer)
				end)
			elseif item.action == "recent" then
				get_recent_files(function(all_items)
					do_fuzzy("Recent Files", all_items, open_buffer)
				end)
			elseif item.action == "commands" then
				get_commands(function(all_items)
					local formatted = {}
					for _, c in ipairs(all_items) do
						table.insert(formatted, {
							text = c.text .. " - " .. c.desc,
							command = c.command,
						})
					end
					do_fuzzy("Commands", formatted, run_command)
				end)
			elseif item.action == "keymaps_n" then
				get_keymaps("n", function(all_items)
					local formatted = {}
					for _, m in ipairs(all_items) do
						table.insert(formatted, {
							text = m.text .. " -> " .. m.rhs,
						})
					end
					do_fuzzy("Normal Keymaps", formatted, function()
					end)
				end)
			elseif item.action == "keymaps_i" then
				get_keymaps("i", function(all_items)
					local formatted = {}
					for _, m in ipairs(all_items) do
						table.insert(formatted, {
							text = m.text .. " -> " .. m.rhs,
						})
					end
					do_fuzzy("Insert Keymaps", formatted, function()
					end)
				end)
			elseif item.action == "keymaps_v" then
				get_keymaps("v", function(all_items)
					local formatted = {}
					for _, m in ipairs(all_items) do
						table.insert(formatted, {
							text = m.text .. " -> " .. m.rhs,
						})
					end
					do_fuzzy("Visual Keymaps", formatted, function()
					end)
				end)
			elseif item.action == "help" then
				get_help_tags(function(all_items)
					do_fuzzy("Help Tags", all_items, show_help)
				end)
			elseif item.action == "grep" then
				vim.ui.input({ prompt = "Grep pattern: " }, function(pattern)
					if not pattern or pattern == "" then
						return
					end
					get_grep_results(pattern, function(all_items)
						do_fuzzy("Grep: " .. pattern, all_items, open_buffer)
					end)
				end)
			end
		end,
	})
end

return M
```

</details>

#### git.lua

<details>
<summary><b>📊 git.lua</b> - Git integrations</summary>

```lua {tangle="lua/git.lua"}

local M = {}

local function get_branches(all_branches, callback)
	local args = all_branches and { "git", "branch", "-a" } or { "git", "branch" }
	vim.system(args, { text = true }, function(obj)
		if obj.code ~= 0 then
			vim.schedule(function()
				callback("Error: " .. obj.stderr)
			end)
			return
		end

		local branches = {}
		for _, line in ipairs(vim.split(obj.stdout, "\n")) do
			local trimmed = vim.trim(line)
			if trimmed ~= "" then
				local is_current = trimmed:match("^%*")
				local name = trimmed:gsub("^%*%s*", ""):gsub("^%s*", "")
				if name ~= "" and not name:match("^%(HEAD detached") then
					table.insert(branches, {
						name = name,
						current = is_current ~= "",
					})
				end
			end
		end

		vim.schedule(function()
			callback(branches)
		end)
	end)
end

local function get_current_branch(callback)
	vim.system({ "git", "branch", "--show-current" }, { text = true }, function(obj)
		vim.schedule(function()
			callback(vim.trim(obj.stdout))
		end)
	end)
end

local function checkout_branch(branch, callback)
	vim.system({ "git", "status", "--porcelain" }, { text = true }, function(status_obj)
		local has_changes = status_obj.stdout and status_obj.stdout ~= ""

		local function do_checkout()
			vim.system({ "git", "checkout", branch }, { text = true }, function(obj)
				vim.schedule(function()
					if obj.code == 0 then
						if has_changes then
							vim.system({ "git", "stash", "pop" }, { text = true }, function()
								callback(true, obj.stdout, obj.stderr)
							end)
						else
							callback(true, obj.stdout, obj.stderr)
						end
					else
						callback(false, obj.stdout, obj.stderr)
					end
				end)
			end)
		end

		if has_changes then
			vim.system({ "git", "stash", "push", "-m", "stashed by nvim-git-picker" }, { text = true }, function(stash_obj)
				if stash_obj.code == 0 then
					do_checkout()
				else
					vim.schedule(function()
						callback(false, stash_obj.stdout, stash_obj.stderr)
					end)
				end
			end)
		else
			do_checkout()
		end
	end)
end

local function get_log(callback)
	vim.system({ "git", "log", "--oneline", "-20" }, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code ~= 0 then
				callback(nil, obj.stderr)
				return
			end
			callback(obj.stdout, nil)
		end)
	end)
end

local function get_status(callback)
	vim.system({ "git", "status", "--porcelain" }, { text = true }, function(obj)
		vim.schedule(function()
			callback(obj.stdout)
		end)
	end)
end

local function commit_to_branch(branch, message, callback)
	vim.system({ "git", "checkout", branch }, { text = true }, function(checkout_obj)
		if checkout_obj.code ~= 0 then
			vim.schedule(function()
				callback(false, "Failed to checkout: " .. checkout_obj.stderr)
			end)
			return
		end

		vim.system({ "git", "add", "-A" }, { text = true }, function(add_obj)
			if add_obj.code ~= 0 then
				vim.schedule(function()
					callback(false, "Failed to stage: " .. add_obj.stderr)
				end)
				return
			end

			vim.system({ "git", "commit", "-m", message }, { text = true }, function(commit_obj)
				vim.schedule(function()
					if commit_obj.code == 0 then
						callback(true, "Committed to: " .. branch)
					else
						callback(false, "Failed to commit: " .. commit_obj.stderr)
					end
				end)
			end)
		end)
	end)
end

local function show_log()
	get_log(function(stdout, stderr)
		if stderr then
			vim.notify("Error: " .. stderr, vim.log.levels.ERROR)
			return
		end

		local lines = vim.split(stdout, "\n")
		if #lines == 0 or (lines[1] and vim.trim(lines[1]) == "") then
			vim.notify("No commits yet", vim.log.levels.WARN)
			return
		end

		local buf_name = "git-log"
		local existing_buf = vim.fn.bufnr(buf_name)
		if existing_buf ~= -1 then
			vim.api.nvim_buf_delete(existing_buf, { force = true })
		end

		local buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_name(buf, buf_name)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = math.floor(vim.o.columns * 0.7),
			height = math.floor(vim.o.lines * 0.6),
			col = math.floor(vim.o.columns * 0.15),
			row = math.floor(vim.o.lines * 0.2),
			border = "rounded",
		})

		vim.api.nvim_win_set_option(win, "wrap", true)
		vim.api.nvim_win_set_option(win, "cursorline", true)
		vim.api.nvim_buf_set_option(buf, "filetype", "git")
		vim.api.nvim_buf_set_option(buf, "modifiable", false)

		vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(win, true)
		end, { buffer = buf, silent = true })

		vim.keymap.set("n", "<Esc>", function()
			vim.api.nvim_win_close(win, true)
		end, { buffer = buf, silent = true })
	end)
end

function M.pick()
	get_current_branch(function(current)
		get_branches(false, function(branches)
			if type(branches) == "string" then
				vim.notify(branches, vim.log.levels.ERROR)
				return
			end

			local items = {
				{
					text = "Switch Branch",
					icon = "󰊢",
					action = "switch",
				},
				{
					text = "Show Git Log",
					icon = "󰟔",
					action = "log",
				},
				{
					text = "Commit to Branch",
					icon = "󰜧",
					action = "commit",
				},
			}

			require("snacks").picker({
				title = "Git (current: " .. (current or "none") .. ")",
				items = items,
				format = function(item, _)
					return {
						{ item.icon, "SnacksPickerIcon" },
						{ " " },
						{ item.text, "SnacksPickerTitle" },
					}
				end,
				layout = { preset = "default" },
				confirm = function(self, item)
					if not item then
						return
					end

					if item.action == "switch" then
						self:close()
						M.switch_branch()
					elseif item.action == "log" then
						self:close()
						show_log()
					elseif item.action == "commit" then
						self:close()
						M.commit()
					end
				end,
			})
		end)
	end)
end

function M.switch_branch()
	get_current_branch(function(current)
		get_branches(true, function(branches)
			if type(branches) == "string" then
				vim.notify(branches, vim.log.levels.ERROR)
				return
			end

			local items = {}
			for _, b in ipairs(branches) do
				table.insert(items, {
					text = b.name,
					branch = b,
				})
			end

			require("snacks").picker({
				title = "Switch Branch (current: " .. (current or "none") .. ")",
				items = items,
				format = function(item, _)
					local icon = "󰊢"
					local hl = "SnacksPickerTitle"
					if item.branch.current then
						icon = "󰜤"
						hl = "SnacksPickerActive"
					elseif item.branch.name:match("^remotes/") then
						icon = "󰤤"
						hl = "SnacksPickerComment"
					end
					return {
						{ icon, "SnacksPickerIcon" },
						{ " " },
						{ item.text, hl },
					}
				end,
				layout = { preset = "default" },
				confirm = function(self, item)
					if item and item.branch then
						self:close()
						checkout_branch(item.branch.name, function(success, stdout, stderr)
							if success then
								vim.notify("Switched to: " .. item.branch.name, vim.log.levels.INFO)
								show_log()
							else
								vim.notify("Error: " .. (stderr or stdout), vim.log.levels.ERROR)
							end
						end)
					end
				end,
			})
		end)
	end)
end

function M.commit()
	get_branches(false, function(branches)
		if type(branches) == "string" then
			vim.notify(branches, vim.log.levels.ERROR)
			return
		end

		get_status(function(status)
			if status == "" then
				vim.notify("No changes to commit", vim.log.levels.WARN)
				return
			end

			local items = {}
			for _, b in ipairs(branches) do
				table.insert(items, {
					text = b.name,
					branch = b,
				})
			end

			require("snacks").picker({
				title = "Commit to Branch",
				items = items,
				format = function(item, _)
					return {
						{ "󰜤", "SnacksPickerIcon" },
						{ " " },
						{ item.text, "SnacksPickerTitle" },
					}
				end,
				layout = { preset = "default" },
				confirm = function(self, item)
					if item and item.branch then
						self:close()
						vim.ui.input({ prompt = "Commit message: " }, function(msg)
							if not msg or msg == "" then
								return
							end
							commit_to_branch(item.branch.name, msg, function(success, output)
								if success then
									vim.notify(output, vim.log.levels.INFO)
									show_log()
								else
									vim.notify(output, vim.log.levels.ERROR)
								end
							end)
						end)
					end
				end,
			})
		end)
	end)
end

function M.log()
	show_log()
end

return M
```

</details>

#### power-commands.lua

<details>
<summary><b>⚡ power-commands.lua</b> - System control</summary>

```lua {tangle="lua/power-commands.lua"}

local M = {}

local function run_cmd(cmd)
	vim.fn.jobstart({ "sh", "-c", cmd })
end

local function playerctl(cmd)
	run_cmd("playerctl " .. cmd .. " 2>/dev/null")
end

local function brightness(action)
	local step = "5%"
	if action == "up" then
		run_cmd("brightnessctl s +" .. step .. " 2>/dev/null")
	elseif action == "down" then
		run_cmd("brightnessctl s " .. step .. "- 2>/dev/null")
	end
end

local function volume(action)
	if action == "up" then
		run_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null")
	elseif action == "down" then
		run_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null")
	elseif action == "mute" then
		run_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null")
	end
end

local commands = {
	{
		category = "Power",
		icon = "󰐥",
		items = {
			{ name = "Shutdown", icon = "󰐥", action = function() run_cmd("systemctl poweroff") end },
			{ name = "Reboot", icon = "󰒉", action = function() run_cmd("systemctl reboot") end },
			{ name = "Sleep", icon = "󰒋", action = function() run_cmd("systemctl suspend") end },
			{ name = "Hibernate", icon = "󰌾", action = function() run_cmd("systemctl hibernate") end },
			{ name = "Lock Screen", icon = "󰌾", action = function() run_cmd("hyprlock") end },
			{ name = "Logout", icon = "󰗼", action = function() run_cmd("loginctl terminate-session $XDG_SESSION_ID") end },
		},
	},
	{
		category = "Media",
		icon = "󰝚",
		items = {
			{ name = "Play/Pause", icon = "󰐌", action = function() playerctl("play-pause") end },
			{ name = "Next Track", icon = "󰒭", action = function() playerctl("next") end },
			{ name = "Previous Track", icon = "󰒮", action = function() playerctl("previous") end },
			{ name = "Stop", icon = "󰓛", action = function() playerctl("stop") end },
			{ name = "Volume Up", icon = "󰝝", action = function() volume("up") end },
			{ name = "Volume Down", icon = "󰝞", action = function() volume("down") end },
			{ name = "Mute/Unmute", icon = "󰝤", action = function() volume("mute") end },
		},
	},
	{
		category = "Brightness",
		icon = "󰛨",
		items = {
			{ name = "Brightness Up", icon = "󰛨", action = function() brightness("up") end },
			{ name = "Brightness Down", icon = "󰛩", action = function() brightness("down") end },
		},
	},
	{
		category = "Screenshot",
		icon = "󰕧",
		items = {
			{ name = "Full Screen", icon = "󰕧", action = function() run_cmd("maim -s ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png && notify-send 'Screenshot saved'") end },
			{ name = "Selection", icon = "󰕧", action = function() run_cmd("maim -s $(xdg-user-dir PICTURES)/screenshot-$(date +%Y%m%d-%H%M%S).png && notify-send 'Screenshot saved'") end },
			{ name = "Copy to Clipboard", icon = "󰆴", action = function() run_cmd("maim -s | xclip -selection clipboard -t image/png && notify-send 'Screenshot copied'") end },
		},
	},
	{
		category = "System",
		icon = "󰒓",
		items = {
			{ name = "Toggle WiFi", icon = "󰤨", action = function() run_cmd("nmcli radio wifi toggle") end },
			{ name = "Toggle Bluetooth", icon = "󰂯", action = function() run_cmd("rfkill toggle bluetooth") end },
			{ name = "Night Light", icon = "󰺿", action = function() run_cmd("redshift -x; redshift -O 4500k 2>/dev/null || echo 'redshift not installed'") end },
			{ name = "Reset Night Light", icon = "󰛨", action = function() run_cmd("redshift -x 2>/dev/null") end },
			{ name = "Kill Wayland", icon = "󰒉", action = function() run_cmd("pkill -9 wayland; pkill -9 weston") end },
		},
	},
}

function M.pick()
	local items = {}

	for _, cat in ipairs(commands) do
		table.insert(items, { text = cat.category, category = true, icon = cat.icon })
		for _, item in ipairs(cat.items) do
			table.insert(items, { text = item.name, cmd = item, icon = item.icon .. " " })
		end
	end

	require("snacks").picker({
		title = "Power Commands",
		items = items,
		format = function(item, _)
			if item.category then
				return { { item.icon, "SnacksPickerIcon" }, { " " }, { item.text, "SnacksPickerTitle" } }
			end
			return { { item.icon, "SnacksPickerIcon" }, { " " }, { item.text, "SnacksPickerTitle" } }
		end,
		layout = { preset = "default" },
		confirm = function(self, item)
			if item and item.cmd and item.cmd.action then
				item.cmd.action()
				self:close()
			end
		end,
	})
end

function M.media(action)
	if action then
		if action == "play-pause" then playerctl("play-pause")
		elseif action == "next" then playerctl("next")
		elseif action == "prev" then playerctl("previous")
		elseif action == "stop" then playerctl("stop")
		elseif action == "volume-up" then volume("up")
		elseif action == "volume-down" then volume("down")
		elseif action == "mute" then volume("mute")
		elseif action == "brightness-up" then brightness("up")
		elseif action == "brightness-down" then brightness("down") end
		return
	end

	local items = {}
	for _, item in ipairs(commands[2].items) do
		table.insert(items, { text = item.name, cmd = item, icon = item.icon .. " " })
	end

	require("snacks").picker({
		title = "Media Controls",
		items = items,
		format = function(item, _)
			return { { item.icon, "SnacksPickerIcon" }, { " " }, { item.text, "SnacksPickerTitle" } }
		end,
		layout = { preset = "ivy" },
		confirm = function(self, item)
			if item and item.cmd and item.cmd.action then
				item.cmd.action()
				self:close()
			end
		end,
	})
end

return M
```

</details>

#### tangle.lua

<details>
<summary><b>🧶 tangle.lua</b> - Extract code blocks from markdown</summary>

````lua {tangle="lua/tangle.lua"}

local M = {}

local handlers = {}

local function get_buf_parser(bufnr, filetype)
	local parser_name = handlers[filetype] and handlers[filetype].parser or filetype
	if not parser_name then return nil end
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, parser_name)
	if not ok then return nil end
	return parser
end

local function ensure_dir(filepath)
	local dir = vim.fn.fnamemodify(filepath, ":p:h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
end

local function files_equal(content, filepath)
	local fd = vim.loop.fs_open(filepath, "r", 0)
	if not fd then return false end
	local stat = vim.loop.fs_fstat(fd)
	if not stat or stat.size == 0 then
		vim.loop.fs_close(fd)
		return false
	end
	local buf = vim.loop.fs_read(fd, stat.size, 0)
	vim.loop.fs_close(fd)
	return buf == content
end

local function write_file(filepath, content)
	ensure_dir(filepath)
	if files_equal(content, filepath) then return false, "unchanged" end
	local fd = vim.loop.fs_open(filepath, "w", 438)
	if not fd then return true, "failed to open" end
	local ok, err = vim.loop.fs_write(fd, content, 0)
	vim.loop.fs_close(fd)
	if not ok then return true, err or "write failed" end
	return false, "written"
end

local function find_fenced_blocks_regex(bufnr)
	local blocks = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local in_fence, fence_lang, fence_info, fence_code, fence_start_row = false, "", "", {}, 0

	for i, line in ipairs(lines) do
		if not in_fence then
			local fence_match, rest = line:match("^%s*```(%w*)(.*)")
			if fence_match ~= nil then
				in_fence, fence_lang, fence_info = true, fence_match or "", rest or ""
				fence_code, fence_start_row = {}, i - 1
			end
		else
			if line:match("^%s*```%s*$") then
				in_fence = false
				local code = table.concat(fence_code, "\n")
				local tangle_file = handlers.markdown.tangle_marker(fence_lang .. " " .. fence_info)
				if tangle_file and code ~= "" then
					table.insert(blocks, { file = tangle_file, code = code, row = fence_start_row })
				end
				fence_lang, fence_info, fence_code = "", "", {}
			else
				table.insert(fence_code, line)
			end
		end
	end
	return blocks
end

handlers.markdown = {
	parser = "markdown",
	tangle_marker = function(info)
		return info:match("tangle%s*=%s*[\"'](.-)[\"']") or info:match("tangle:%s*(%S+)")
	end,
	get_code = function(node, bufnr)
		local start_row, start_col, end_row, end_col = node:range()
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		if #lines == 0 then return "" end
		if start_col > 0 then lines[1] = lines[1]:sub(start_col + 1) end
		if end_col > 0 and #lines > 0 then lines[#lines] = lines[#lines]:sub(1, end_col) end
		return table.concat(lines, "\n"):gsub("\n?```%s*$", "")
	end,
	find_blocks = function(parser, bufnr)
		if not parser then return find_fenced_blocks_regex(bufnr) end
		local tree, root = parser:parse()[1], tree:root()
		local blocks = {}
		local function walk(node)
			if node:type() == "fenced_code_block" then
				local info_node, code_node
				for child in node:iter_children() do
					local ct = child:type()
					if ct == "info_string" then info_node = child
					elseif ct == "code_fence_content" then code_node = child end
				end
				local info = ""
				if info_node then
					local s, _, e, _ = info_node:range()
					local lines = vim.api.nvim_buf_get_lines(bufnr, s, e + 1, false)
					info = table.concat(lines, " ")
				end
				local tangle_file = handlers.markdown.tangle_marker(info)
				if code_node and tangle_file then
					local code = handlers.markdown.get_code(code_node, bufnr)
					local start_row = node:range()
					table.insert(blocks, { file = tangle_file, code = code, row = start_row })
				end
			end
			for child in node:iter_children() do walk(child) end
		end
		walk(root)
		return blocks
	end,
}

handlers.yaml = {
	parser = "yaml",
	tangle_marker = function(info)
		local key = info or ""
		return key:match("|([^|]+)$") or key:match("tangle%s*=%s*(%S+)") or key:match("tangle:%s*(%S+)")
	end,
	find_blocks = function(parser, bufnr)
		local blocks = find_fenced_blocks_regex(bufnr)
		table.sort(blocks, function(a, b) return a.row < b.row end)
		return blocks
	end,
}

handlers.conf = { parser = nil, find_blocks = find_fenced_blocks_regex }
handlers.hyprlang = { parser = nil, find_blocks = find_fenced_blocks_regex }

local function get_handler(bufnr)
	local ft = vim.bo[bufnr].filetype
	return handlers[ft]
end

local function setup_virtual_text(blocks, bufnr)
	local ns = vim.api.nvim_create_namespace("tangle")
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	for _, block in ipairs(blocks) do
		local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns, { block.row, 0 }, { block.row, -1 }, {})
		if #extmarks == 0 then
			vim.api.nvim_buf_set_extmark(bufnr, ns, block.row, 0, {
				virt_text = { { " -> " .. block.file, "Comment" } },
				virt_text_pos = "eol",
			})
		end
	end
end

function M.tangle()
	local bufnr = vim.api.nvim_get_current_buf()
	local handler = get_handler(bufnr)
	if not handler then return end

	local blocks
	if handler.parser then
		local parser = get_buf_parser(bufnr, vim.bo[bufnr].filetype)
		if not parser then
			blocks = find_fenced_blocks_regex(bufnr)
		else
			blocks = handler.find_blocks(parser, bufnr)
		end
	else
		blocks = handler.find_blocks(bufnr)
	end

	if #blocks == 0 then
		vim.notify("[tangle] No blocks with tangle metadata found", vim.log.levels.INFO)
		return
	end

	setup_virtual_text(blocks, bufnr)

	local outputs = {}
	for _, block in ipairs(blocks) do
		if not outputs[block.file] then outputs[block.file] = {} end
		table.insert(outputs[block.file], block.code)
	end

	local written, skipped, errors = 0, 0, {}
	for filepath, codes in pairs(outputs) do
		local content = table.concat(codes, "\n\n")
		local err, status = write_file(filepath, content)
		if status == "written" then written = written + 1
		elseif status == "unchanged" then skipped = skipped + 1
		else table.insert(errors, filepath .. ": " .. status) end
	end

	if #errors > 0 then
		vim.notify("[tangle] Errors: " .. table.concat(errors, ", "), vim.log.levels.ERROR)
	else
		vim.notify(string.format("[tangle] Written %d, skipped %d files", written, skipped), vim.log.levels.INFO)
	end
end

function M.setup()
	vim.api.nvim_create_user_command("Tangle", function() M.tangle() end, { desc = "Tangle code blocks from supported files" })
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = { "*.md", "*.yml", "*.yaml", "*.conf" },
		callback = function(args)
			if vim.b[args.buf].auto_tangle then M.tangle() end
		end,
	})
end

return M
````

</details>

#### web-search.lua

<details>
<summary><b>🌐 web-search.lua</b> - Web search from Neovim</summary>

```lua {tangle="lua/web-search.lua"}

local M = {}

local search_engines = {
	{ name = "DuckDuckGo", icon = "🔍", url = "https://duckduckgo.com/?q=", desc = "Default search engine" },
	{ name = "URL", icon = "🌐", url = "", desc = "enter custom URL", custom = true },
	{ name = "Wikipedia", icon = "📚", url = "https://en.wikipedia.org/wiki/Special:Search?search=", desc = "Wikipedia encyclopedia" },
	{ name = "YouTube", icon = "▶️", url = "https://www.youtube.com/results?search_query=", desc = "YouTube videos" },
	{ name = "GitHub", icon = "󰤤", url = "https://github.com/search?q=", desc = "GitHub code search" },
	{ name = "Stack Overflow", icon = "󰌆", url = "https://stackoverflow.com/search?q=", desc = "Stack Overflow questions" },
	{ name = "Reddit", icon = "󰑔", url = "https://www.reddit.com/search/?q=", desc = "Reddit search" },
	{ name = "Web (DuckDuckGo)", icon = "🌍", url = "https://html.duckduckgo.com/html/?q=", desc = "Web search (minimal)" },
	{ name = "Browse in Neovim (w3m)", icon = "󰀯", url = "https://duckduckgo.com/?q=", desc = "Open in neovim terminal browser", nvim = true },
}

local function open_url(url)
	vim.fn.jobstart({ "xdg-open", url })
end

local function open_in_browser(url)
	require("text-browser").browse(url)
end

local function url_encode(str)
	if str then
		str = str:gsub("\n", "\r\n")
		str = str:gsub("([^%w %-%_%.%~])", function(c) return string.format("%%%02X", string.byte(c)) end)
		str = str:gsub(" ", "%%20")
	end
	return str
end

local function build_search_url(query, engine)
	return engine.url .. url_encode(query)
end

function M.search()
	vim.ui.input({ prompt = "Search: " }, function(query)
		if not query or query == "" then return end

		local items = {}
		for _, engine in ipairs(search_engines) do
			table.insert(items, { text = engine.name, engine = engine, query = query })
		end

		require("snacks").picker({
			title = "Search: " .. query,
			items = items,
			format = function(item, _)
				return {
					{ item.engine.icon, "SnacksPickerIcon" },
					{ " " },
					{ item.text, "SnacksPickerTitle" },
					{ " | " .. item.engine.desc, "SnacksPickerComment" },
				}
			end,
			layout = { preset = "default" },
			confirm = function(self, item)
				if item and item.engine then
					if item.engine.custom then
						vim.ui.input({ prompt = "Enter URL: " }, function(url)
							if url and url ~= "" then open_url(url) end
						end)
					else
						local url = build_search_url(item.query, item.engine)
						if item.engine.nvim then open_in_browser(url) else open_url(url) end
					end
					self:close()
				end
			end,
		})
	end)
end

return M
```

</details>

</details>

---

_Thanks for supporting!_
