local M = {}

M._terms = {}

local verify_terms = function(type)
	if M._terms[type] == nil then
		return
	end

	local valid_terms = M._terms[type]
	local index = 1
	while index <= #valid_terms do
		if not vim.api.nvim_buf_is_valid(valid_terms[index].buf) then
			table.remove(valid_terms, index)
		else
			index = index + 1
		end
	end

	for id, term in ipairs(valid_terms) do
		term.id = id
	end

	M._terms[type] = valid_terms
end

local function get_open_term(type)
	local terms = M._terms[type] or {}
	for _, term in ipairs(terms) do
		if term.open then
			return term
		end
	end
end

local function get_last_term(type)
	local terms = M._terms[type] or {}
	if #terms > 0 then
		return terms[#terms]
	end
	return nil
end

local function close_term(type)
	local open_term = get_open_term(type)
	if open_term then
		M._terms[type][open_term.id].open = false
	end
end

M.create_and_show_term = function(type, win, config, shell_override)
	verify_terms(type)
	close_term(type)

	local terms = M._terms[type] or {}
	local id = #terms + 1
	local buf = vim.api.nvim_create_buf(false, true)
	local term = { id = id, buf = buf, open = true, type = type }

	terms[id] = term
	M._terms[type] = terms

	vim.api.nvim_win_set_buf(win, term.buf)
	vim.fn.termopen(config.shell or shell_override or vim.o.shell)
	vim.cmd("startinsert")
end

M.toggle_term_in_win = function(type, win, config)
	verify_terms(type)

	local existing_term = get_open_term(type) or get_last_term(type)
	if existing_term then
		M._terms[type][existing_term.id].open = true
		vim.api.nvim_win_set_buf(win, existing_term.buf)
		vim.cmd("startinsert")
	else
		M.create_and_show_term(type, win, config)
	end
end

M.switch_to_next_term = function(type, win)
	verify_terms(type)

	local open_term = get_open_term(type)
	if not open_term then
		return
	end

	local next_term_id = open_term.id + 1
	if next_term_id > #M._terms[type] then
		next_term_id = 1
	end
	local next_term = nil

	while next_term_id ~= open_term.id and next_term == nil do
		if next_term_id > #M._terms[type] then
			next_term_id = 1
		end

		if M._terms[type][next_term_id].open == false then
			next_term = M._terms[type][next_term_id]
		end

		next_term_id = next_term_id + 1
	end

	if next_term then
		M._terms[type][open_term.id].open = false
		M._terms[type][next_term.id].open = true
		vim.api.nvim_win_set_buf(win, next_term.buf)
		vim.cmd("startinsert")
	end
end

M.close_term_buffers = function()
	for _, terms in pairs(M._terms) do
		vim.tbl_map(function(term)
			vim.cmd("bd! " .. tostring(term.buf))
		end, terms)
	end
end

return M
