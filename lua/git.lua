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

local function push_to_remote(remote, branch, callback)
	vim.system({ "git", "push", remote, branch }, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code == 0 then
				callback(true, "Pushed to " .. remote .. "/" .. branch)
			else
				callback(false, "Push failed: " .. obj.stderr)
			end
		end)
	end)
end

local function get_remotes(callback)
	vim.system({ "git", "remote", "-v" }, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code ~= 0 then
				callback(nil, obj.stderr)
				return
			end

			local remotes = {}
			for _, line in ipairs(vim.split(obj.stdout, "\n")) do
				local name = line:match("^([^%s]+)")
				if name and not remotes[name] then
					remotes[name] = true
				end
			end

			local remote_list = vim.tbl_keys(remotes)
			table.sort(remote_list)
			callback(remote_list, nil)
		end)
	end)
end

local function commit_and_push(branch, message, callback)
	commit_to_branch(branch, message, function(success, output)
		if not success then
			callback(false, output)
			return
		end

		get_current_branch(function(current_branch)
			push_to_remote("origin", current_branch, function(push_success, push_output)
				if push_success then
					callback(true, output .. "\n" .. push_output)
				else
					callback(false, output .. "\n" .. push_output)
				end
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
				{
					text = "Push to Remote",
					icon = "󰊤",
					action = "push",
				},
				{
					text = "Commit & Push",
					icon = "󰜏",
					action = "commit_push",
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
					elseif item.action == "push" then
						self:close()
						M.push()
					elseif item.action == "commit_push" then
						self:close()
						M.commit_push()
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

function M.push()
	get_current_branch(function(branch)
		if not branch or branch == "" then
			vim.notify("Not on a branch", vim.log.levels.ERROR)
			return
		end

		get_status(function(status)
			local has_unpushed = false
			if status == "" then
				has_unpushed = false
			else
				vim.system({ "git", "log", "@{u}..HEAD", "--oneline" }, { text = true }, function(obj)
					has_unpushed = obj.stdout and obj.stdout ~= ""
				end)
			end

			get_remotes(function(remotes, err)
				if err then
					vim.notify("Error getting remotes: " .. err, vim.log.levels.ERROR)
					return
				end

				if #remotes == 0 then
					vim.notify("No remotes configured", vim.log.levels.ERROR)
					return
				end

				local items = {}
				for _, r in ipairs(remotes) do
					table.insert(items, {
						text = r .. "/" .. branch,
						remote = r,
						branch = branch,
					})
				end

				require("snacks").picker({
					title = "Push to Remote (branch: " .. branch .. ")",
					items = items,
					format = function(item, _)
						return {
							{ "󰊤", "SnacksPickerIcon" },
							{ " " },
							{ item.text, "SnacksPickerTitle" },
						}
					end,
					layout = { preset = "default" },
					confirm = function(self, item)
						if item then
							self:close()
							push_to_remote(item.remote, item.branch, function(success, output)
								if success then
									vim.notify(output, vim.log.levels.INFO)
								else
									vim.notify(output, vim.log.levels.ERROR)
								end
							end)
						end
					end,
				})
			end)
		end)
	end)
end

function M.commit_push()
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
				title = "Commit & Push Branch",
				items = items,
				format = function(item, _)
					return {
						{ "󰜏", "SnacksPickerIcon" },
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
							commit_and_push(item.branch.name, msg, function(success, output)
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

return M
