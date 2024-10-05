local M = {}

M._wins = {}

local function get_win_opts(type, config)
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

local verify_wins = function()
	local valid_wins = {}

	for type, win in pairs(M._wins) do
		if vim.api.nvim_win_is_valid(win) then
			valid_wins[type] = win
		end
	end

	M._wins = valid_wins
end

M.create_or_get_win = function(type, config)
	verify_wins()

	if M._wins[type] then
		return M._wins[type]
	end

	local win_opts = get_win_opts(type, config)
	vim.api.nvim_open_win(0, true, win_opts)

	vim.wo.relativenumber = false
	vim.wo.number = false

	local win = vim.api.nvim_get_current_win()
	M._wins[type] = win
	return win
end

M.get_win = function(type)
	verify_wins()
	return M._wins[type]
end

M.close_win = function(type)
	local win = M._wins[type]

	if win == nil then
		return
	end

	local wins = vim.api.nvim_list_wins()
	if #wins == 1 then
		vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(false, false))
	else
		vim.api.nvim_win_close(win, false)
	end
	M._wins[type] = nil
end

M.get_wins = function()
	verify_wins()
	return M._wins
end

M.get_win_type = function(win)
	for type, current_win in pairs(M._wins) do
		if win == current_win then
			return type
		end
	end
	return nil
end

return M
