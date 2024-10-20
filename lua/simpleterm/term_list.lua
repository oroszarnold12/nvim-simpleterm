local M = {}

local term_name_regex = "([^/]+)$"
local term_icon

local get_term_icon = function()
	if term_icon == nil then
		term_icon = require("nvim-web-devicons").get_icon("terminal", "sh", { default = true })
	end

	return term_icon
end

M.render_term_names = function(win, terms)
	local buf = vim.api.nvim_create_buf(false, true)
	local lines = {}

	for _, term in ipairs(terms) do
		local prefix = term.open and "> " or "  "
		local shell = string.match(term.shell, term_name_regex)
		table.insert(lines, prefix .. get_term_icon() .. "  " .. shell)
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	for line_num = 0, vim.api.nvim_buf_line_count(buf) - 1 do
		local term_id = line_num + 1
		if terms[term_id].open then
			vim.api.nvim_buf_add_highlight(buf, -1, "CursorLineNr", line_num, 0, -1)
		else
			vim.api.nvim_buf_add_highlight(buf, -1, "LineNr", line_num, 0, -1)
		end
	end

	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_win_set_buf(win, buf)
end

return M
