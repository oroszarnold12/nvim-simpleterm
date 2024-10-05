local term_util = require("simpleterm.term_util")
local win_util = require("simpleterm.win_util")

local M = {}
local config = {}

local function new(type, shell_override)
	local win = win_util.create_or_get_win(type, config)
	term_util.create_and_show_term(type, win, config, shell_override)
end

local function toggle(type)
	local win = win_util.get_win(type)

	if win then
		win_util.close_win(type)
	else
		local new_win = win_util.create_or_get_win(type, config)
		term_util.toggle_term_in_win(type, new_win, config)
	end
end

M.toggle_vertical = function()
	toggle("vertical")
end

M.toggle_horizontal = function()
	toggle("horizontal")
end

M.toggle_floating = function()
	toggle("floating")
end

M.new_vertical = function(shell_override)
	new("vertical", shell_override)
end

M.new_horizontal = function(shell_override)
	new("horizontal", shell_override)
end

M.new_floating = function(shell_override)
	new("floating", shell_override)
end

M.next_term_buffer = function()
	local current_win = vim.api.nvim_get_current_win()
	local type = win_util.get_win_type(current_win)

	if not type then
		return
	end

	term_util.switch_to_next_term(type, current_win)
end

M.init = function(conf)
	config = conf
end

return M
