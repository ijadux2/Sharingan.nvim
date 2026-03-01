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
				"## " .. title,
				"",
			}

			vim.cmd("edit " .. filepath)
			vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
			vim.cmd("write")
		end)
	end)
end

function M.setup()
	vim.keymap.set("n", "<S-f>", M.create_note, { desc = "Create Markdown Note" })
end

return M
