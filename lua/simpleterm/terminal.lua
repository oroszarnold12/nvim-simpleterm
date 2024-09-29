local util = require("simpleterm.termutil")

local simpleterm = {}
local terminals = {}
local windows = {}
local config = {}

local function create_term(type, buf)
	local id = #terminals + 1
	local term = { id = id, buf = buf, open = true, type = type }
	terminals[id] = term
	return term
end

local function show_term_in_win(term, win)
	terminals[term.id].open = true
	vim.api.nvim_win_set_buf(win, term.buf)
	vim.cmd("startinsert")
end

local function get_terms(type, list)
	list = list or terminals
	return vim.tbl_filter(function(t)
		return t.type == type
	end, list)
end

local function get_open_terms()
	if not terminals then
		return {}
	end
	return #terminals > 0 and vim.tbl_filter(function(t)
		return t.open == true
	end, terminals) or {}
end

local function get_open_term_with_type(type)
	local open_with_type = get_terms(type, get_open_terms())
	if #open_with_type == 1 then
		return open_with_type[1]
	end
	return nil
end

local function get_last_term_with_type(type)
	local terms_with_type = get_terms(type)
	if #terms_with_type > 0 then
		return terms_with_type[#terms_with_type]
	end
	return nil
end

local function close_term_with_type(type)
	local open_terminal = get_open_term_with_type(type)
	if open_terminal then
		terminals[open_terminal.id].open = false
	end
end

local function create_win(type)
	util.split(type, config)
	vim.wo.relativenumber = false
	vim.wo.number = false

	local win = vim.api.nvim_get_current_win()
	windows[type] = win
	return win
end

local function create_or_get_win(type)
	if windows[type] then
		return windows[type]
	end
	return create_win(type)
end

local function close_win(type)
	vim.api.nvim_win_close(windows[type], false)
	windows[type] = nil
end

local function get_win_type(win)
	for key, value in pairs(windows) do
		if value == win then
			return key
		end
	end
	return nil
end

local function create_buf()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "terminal")
	return buf
end

local function new(type, shell_override)
	windows = util.verify_windows(windows)
	terminals = util.verify_terminals(terminals)

	close_term_with_type(type)

	local win = create_or_get_win(type)
	local buf = create_buf()
	local term = create_term(type, buf)

	show_term_in_win(term, win)
	vim.fn.termopen(config.shell or shell_override or vim.o.shell)

	return term
end

local function toggle(type)
	windows = util.verify_windows(windows)
	terminals = util.verify_terminals(terminals)

	local term = get_open_term_with_type(type) or get_last_term_with_type(type)

	if not term then
		term = new(type)
	elseif windows[type] then
		close_win(type)
	else
		local win = create_win(type)
		show_term_in_win(term, win)
	end
end

simpleterm.toggle_vertical = function()
	toggle("vertical")
end

simpleterm.toggle_horizontal = function()
	toggle("horizontal")
end

simpleterm.toggle_floating = function()
	toggle("floating")
end

simpleterm.new_vertical = function(shell_override)
	new("vertical", shell_override)
end

simpleterm.new_horizontal = function(shell_override)
	new("horizontal", shell_override)
end

simpleterm.new_floating = function(shell_override)
	new("floating", shell_override)
end

simpleterm.next_term_buffer = function()
	windows = util.verify_windows(windows)
	terminals = util.verify_terminals(terminals)

	local current_win = vim.api.nvim_get_current_win()
	local type = get_win_type(current_win)

	if not type then
		return
	end

	local open_term_with_type = get_open_term_with_type(type)
	if not open_term_with_type then
		return
	end

	local next_term_id = open_term_with_type.id + 1
	if next_term_id > #terminals then
		next_term_id = 1
	end

	local next_term = nil

	while next_term_id ~= open_term_with_type.id and next_term == nil do
		if next_term_id > #terminals then
			next_term_id = 1
		end

		if terminals[next_term_id].open == false and terminals[next_term_id].type == type then
			next_term = terminals[next_term_id]
		end

		next_term_id = next_term_id + 1
	end

	if next_term ~= nil then
		close_term_with_type(type)
		show_term_in_win(next_term, current_win)
	end
end

simpleterm.close_buffers = function()
	vim.tbl_map(function(terminal)
		vim.cmd("bd! " .. tostring(terminal.buf))
	end, terminals)
end

simpleterm.get_windows = function()
	windows = util.verify_windows(windows)
	return windows
end

simpleterm.init = function(conf)
	config = conf
end

return simpleterm
