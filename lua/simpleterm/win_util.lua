local M = {}

M._wins = {}

local function get_term_win_opts(type, config)
	local type_opts = config.type_opts[type]

	if type == "floating" then
		return {
			relative = "editor",
			width = math.ceil(type_opts.width * vim.o.columns),
			height = math.ceil(type_opts.height * vim.o.lines),
			row = math.floor(type_opts.row * vim.o.lines),
			col = math.floor(type_opts.col * vim.o.columns),
			border = type_opts.border,
		}
	elseif type == "horizontal" then
		local height = math.floor(vim.api.nvim_win_get_height(0) * type_opts.split_ratio)
		return { split = "below", height = height }
	else
		local width = math.floor(vim.api.nvim_win_get_width(0) * type_opts.split_ratio)
		return { split = "right", width = width }
	end
end

local function get_list_win_opts(type, config)
	local type_opts = config.type_opts[type]

	if type == "floating" then
		return {
			relative = "editor",
			width = math.ceil(type_opts.list_width),
			height = math.ceil(type_opts.height * vim.o.lines),
			row = math.floor(type_opts.row * vim.o.lines),
			col = math.floor((type_opts.col + type_opts.width) * vim.o.columns),
			border = type_opts.border,
		}
	else
		return { split = "right", width = type_opts.list_width }
	end
end

M.verify_wins = function()
	local valid_wins = {}

	for type, win in pairs(M._wins) do
		if vim.api.nvim_win_is_valid(win.term_win) then
			valid_wins[type] = win
		elseif vim.api.nvim_win_is_valid(win.list_win) then
			vim.api.nvim_win_close(win.list_win, false)
		end
	end

	M._wins = valid_wins
end

M.create_or_get_win = function(type, config)
	if M._wins[type] then
		return M._wins[type]
	end

	local term_win_opts = get_term_win_opts(type, config)
	local list_win_opts = get_list_win_opts(type, config)
	local term_win = vim.api.nvim_open_win(0, true, term_win_opts)
	local list_win = vim.api.nvim_open_win(0, false, list_win_opts)

	vim.api.nvim_set_option_value("number", false, { win = list_win })
	vim.api.nvim_set_option_value("relativenumber", false, { win = list_win })
	vim.api.nvim_set_option_value("cursorline", false, { win = list_win })

	vim.wo.relativenumber = false
	vim.wo.number = false

	M._wins[type] = { term_win = term_win, list_win = list_win }
	return M._wins[type]
end

M.get_win = function(type)
	return M._wins[type]
end

M.close_win = function(type)
	if M._wins[type] == nil then
		return
	end

	local term_win = M._wins[type].term_win
	local list_win = M._wins[type].list_win

	local wins = vim.api.nvim_list_wins()
	if #wins == 2 then
		vim.api.nvim_win_set_buf(term_win, vim.api.nvim_create_buf(false, false))
	else
		vim.api.nvim_win_close(term_win, false)
	end
	vim.api.nvim_win_close(list_win, false)

	M._wins[type] = nil
end

M.get_wins = function()
	local wins = {}

	for _, win in pairs(M._wins) do
		table.insert(wins, win.term_win)
		table.insert(wins, win.list_win)
	end

	return wins
end

M.get_win_type = function(win)
	for type, current_win in pairs(M._wins) do
		if win == current_win.term_win then
			return type
		end
	end
	return nil
end

return M
