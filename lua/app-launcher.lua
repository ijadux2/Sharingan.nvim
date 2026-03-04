local M = {}

local app_cache = {}
local cache_time = 0
local CACHE_TTL = 300

local function parse_desktop_file(file_path)
	local app = {
		name = "",
		exec = "",
		icon = "󰣆",
		category = "desktop",
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

local function scan_flatpak_apps()
	local apps = {}
	local handle = io.popen("flatpak list --app --columns=application,name 2>/dev/null")
	if handle then
		for line in handle:lines() do
			local app_id, name = line:match("^([^\t]+)\t([^\t]+)")
			if app_id and name then
				table.insert(apps, {
					name = name,
					exec = "flatpak run " .. app_id,
					icon = "󰏣",
					category = "flatpak",
				})
			end
		end
		handle:close()
	end
	return apps
end

local function scan_desktop_apps()
	local apps = {}

	local dirs = {
		"/usr/share/applications",
		"/usr/local/share/applications",
		vim.fn.expand("~/.local/share/applications"),
	}

	for _, dir in ipairs(dirs) do
		local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
		if handle then
			for file in handle:lines() do
				if file:match("%.desktop$") then
					local app = parse_desktop_file(dir .. "/" .. file)
					if app and app.name and app.name ~= "" and app.exec and app.exec ~= "" then
						table.insert(apps, app)
					end
				end
			end
			handle:close()
		end
	end

	return apps
end

local function scan_applications()
	local current_time = os.time()
	if #app_cache > 0 and (current_time - cache_time) < CACHE_TTL then
		return app_cache
	end

	local desktop_apps = scan_desktop_apps()
	local flatpak_apps = scan_flatpak_apps()

	local all_apps = {}
	for _, app in ipairs(desktop_apps) do
		table.insert(all_apps, app)
	end
	for _, app in ipairs(flatpak_apps) do
		table.insert(all_apps, app)
	end

	table.sort(all_apps, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	app_cache = all_apps
	cache_time = current_time
	return all_apps
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
		local icon = app.icon
		if app.category == "flatpak" then
			icon = "󰏣"
		elseif app.category == "desktop" then
			icon = "󰣆"
		end
		table.insert(items, {
			text = app.name,
			exec = app.exec,
			icon = icon,
			category = app.category,
		})
	end

	require("snacks").picker({
		title = "Applications",
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

function M.refresh()
	app_cache = {}
	cache_time = 0
end

return M
