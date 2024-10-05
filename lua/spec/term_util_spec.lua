local mock = require("luassert.mock")
local stub = require("luassert.stub")
local assert = require("luassert")

local default_config = {
	type_opts = {
		horizontal = { location = "rightbelow", split_ratio = 0.3 },
		vertical = { location = "rightbelow", split_ratio = 0.5 },
		floating = {
			relative = "editor",
			row = 0.3,
			col = 0.25,
			width = 0.5,
			height = 0.4,
			border = "single",
		},
	},
	behavior = {
		autoclose_on_quit = {
			enabled = false,
			confirm = true,
		},
		close_on_exit = true,
		auto_insert = true,
	},
	shell = "/bin/bash",
}

describe("term_util", function()
	local term_util = require("simpleterm.term_util")
	local type = "horizontal"

	after_each(function()
		term_util._terms = {}
	end)

	describe("create_and_show_term", function()
		it("creates and shows a new terminal", function()
			local api_mock = mock(vim.api)

			local win = vim.api.nvim_get_current_win()

			term_util.create_and_show_term(type, win, default_config)

			assert.are.same({ [type] = { [1] = { id = 1, buf = 2, open = true, type = type } } }, term_util._terms)
			assert.stub(api_mock.nvim_create_buf).was_called_with(false, true)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, 2)

			mock.revert(api_mock)
		end)

		it("creates multiple new terminals", function()
			local api_mock = mock(vim.api, true)
			local fn_mock = mock(vim.fn, true)

			local win = 1
			local buf1 = 2
			local buf2 = 3

			api_mock.nvim_buf_is_valid.returns(true)
			api_mock.nvim_create_buf.returns(buf1)

			term_util.create_and_show_term(type, win, default_config)
			assert.are.same({ [type] = { [1] = { id = 1, buf = buf1, open = true, type = type } } }, term_util._terms)

			api_mock.nvim_create_buf.returns(buf2)
			term_util.create_and_show_term(type, win, default_config)
			assert.are.same({
				[type] = {
					[1] = { id = 1, buf = buf1, open = false, type = type },
					[2] = { id = 2, buf = buf2, open = true, type = type },
				},
			}, term_util._terms)

			assert.stub(api_mock.nvim_create_buf).was_called_with(false, true)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, buf1)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, buf2)
			assert.stub(fn_mock.termopen).was_called_with(default_config.shell)

			mock.revert(api_mock)
			mock.revert(fn_mock)
		end)

		it("creates multiple new terminals when remaining terminal is invalid", function()
			local api_mock = mock(vim.api, true)
			local fn_mock = mock(vim.fn, true)

			local win = 1
			local buf = 2

			api_mock.nvim_buf_is_valid.returns(false)
			api_mock.nvim_create_buf.returns(buf)

			term_util.create_and_show_term(type, win, default_config)
			assert.are.same({ [type] = { [1] = { id = 1, buf = buf, open = true, type = type } } }, term_util._terms)

			term_util.create_and_show_term(type, win, default_config)
			assert.are.same({ [type] = { [1] = { id = 1, buf = buf, open = true, type = type } } }, term_util._terms)

			assert.stub(api_mock.nvim_create_buf).was_called_with(false, true)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, buf)
			assert.stub(fn_mock.termopen).was_called_with(default_config.shell)

			mock.revert(api_mock)
			mock.revert(fn_mock)
		end)
	end)

	describe("toggle_term_in_win", function()
		it("creates new terminal if there is no existing terminal", function()
			local win = 1
			local create_and_show_terminal_mock = stub(term_util, "create_and_show_term")

			term_util.toggle_term_in_win(type, win, default_config)

			assert.stub(create_and_show_terminal_mock).was_called_with(type, win, default_config)
		end)

		it("shows the already open terminal if exists", function()
			local win = 1
			local existing_open_term_buf = 3
			local api_mock = mock(vim.api, true)

			api_mock.nvim_buf_is_valid.returns(true)

			term_util._terms = {
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = existing_open_term_buf, open = true, type = type },
					[4] = { id = 4, buf = 4, open = false, type = type },
				},
			}

			term_util.toggle_term_in_win(type, win, default_config)

			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, existing_open_term_buf)
			assert.are.same({
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = existing_open_term_buf, open = true, type = type },
					[4] = { id = 4, buf = 4, open = false, type = type },
				},
			}, term_util._terms)

			mock.revert(api_mock)
		end)

		it("shows last valid terminal if there is any", function()
			local win = 1
			local last_term_buffer = 4
			local api_mock = mock(vim.api, true)

			api_mock.nvim_buf_is_valid.on_call_with(1).returns(true)
			api_mock.nvim_buf_is_valid.on_call_with(2).returns(false)
			api_mock.nvim_buf_is_valid.on_call_with(3).returns(true)
			api_mock.nvim_buf_is_valid.on_call_with(4).returns(true)

			term_util._terms = {
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = 3, open = false, type = type },
					[4] = { id = 4, buf = last_term_buffer, open = false, type = type },
				},
			}

			term_util.toggle_term_in_win(type, win, default_config)

			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, last_term_buffer)
			assert.are.same({
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 3, open = false, type = type },
					[3] = { id = 3, buf = last_term_buffer, open = true, type = type },
				},
			}, term_util._terms)

			mock.revert(api_mock)
		end)

		it("creates new terminal if existing terminals were all invalid", function()
			local win = 1
			local api_mock = mock(vim.api, true)

			local create_and_show_terminal_mock = stub(term_util, "create_and_show_term")
			api_mock.nvim_buf_is_valid.returns(false)

			term_util._terms = {
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = 3, open = false, type = type },
					[4] = { id = 4, buf = 4, open = false, type = type },
				},
			}

			term_util.toggle_term_in_win(type, win, default_config)
			assert.are.same({ [type] = {} }, term_util._terms)

			assert.stub(create_and_show_terminal_mock).was_called_with(type, win, default_config)

			mock.revert(api_mock)
		end)
	end)

	describe("switch_to_next_term", function()
		it("switches to the terminal right after the current terminal", function()
			local win = 1
			local api_mock = mock(vim.api, true)
			local next_term_buf = 4

			api_mock.nvim_buf_is_valid.returns(true)

			term_util._terms = {
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = 3, open = true, type = type },
					[4] = { id = 4, buf = next_term_buf, open = false, type = type },
				},
			}

			term_util.switch_to_next_term(type, win)

			assert.are.same({
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = 3, open = false, type = type },
					[4] = { id = 4, buf = next_term_buf, open = true, type = type },
				},
			}, term_util._terms)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, next_term_buf)

			mock.revert(api_mock)
		end)

		it("switches to the first terminal after the last", function()
			local win = 1
			local api_mock = mock(vim.api, true)
			local next_term_buf = 1

			api_mock.nvim_buf_is_valid.returns(true)

			term_util._terms = {
				[type] = {
					[1] = { id = 1, buf = next_term_buf, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = 3, open = false, type = type },
					[4] = { id = 4, buf = 4, open = true, type = type },
				},
			}

			term_util.switch_to_next_term(type, win)

			assert.are.same({
				[type] = {
					[1] = { id = 1, buf = next_term_buf, open = true, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = 3, open = false, type = type },
					[4] = { id = 4, buf = 4, open = false, type = type },
				},
			}, term_util._terms)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, next_term_buf)

			mock.revert(api_mock)
		end)

		it("switches to the first valid terminal after the last", function()
			local win = 1
			local api_mock = mock(vim.api, true)
			local next_term_buf = 2

			api_mock.nvim_buf_is_valid.on_call_with(1).returns(false)
			api_mock.nvim_buf_is_valid.on_call_with(2).returns(true)
			api_mock.nvim_buf_is_valid.on_call_with(3).returns(true)
			api_mock.nvim_buf_is_valid.on_call_with(4).returns(true)

			term_util._terms = {
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = next_term_buf, open = false, type = type },
					[3] = { id = 3, buf = 3, open = false, type = type },
					[4] = { id = 4, buf = 4, open = true, type = type },
				},
			}

			term_util.switch_to_next_term(type, win)

			assert.are.same({
				[type] = {
					[1] = { id = 1, buf = next_term_buf, open = true, type = type },
					[2] = { id = 2, buf = 3, open = false, type = type },
					[3] = { id = 3, buf = 4, open = false, type = type },
				},
			}, term_util._terms)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, next_term_buf)

			mock.revert(api_mock)
		end)

		it("does not do anything if there is no terminal", function()
			local win = 1
			local api_mock = mock(vim.api, true)

			api_mock.nvim_buf_is_valid.returns(true)

			term_util.switch_to_next_term(type, win)

			assert.are.same({}, term_util._terms)
			assert.stub(api_mock.nvim_win_set_buf).was_not_called()

			mock.revert(api_mock)
		end)

		it("does not do anything if there is no open terminal", function()
			local win = 1
			local api_mock = mock(vim.api, true)

			api_mock.nvim_buf_is_valid.returns(true)

			term_util._terms = {
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = 3, open = false, type = type },
					[4] = { id = 4, buf = 4, open = false, type = type },
				},
			}

			term_util.switch_to_next_term(type, win)

			assert.are.same({
				[type] = {
					[1] = { id = 1, buf = 1, open = false, type = type },
					[2] = { id = 2, buf = 2, open = false, type = type },
					[3] = { id = 3, buf = 3, open = false, type = type },
					[4] = { id = 4, buf = 4, open = false, type = type },
				},
			}, term_util._terms)
			assert.stub(api_mock.nvim_win_set_buf).was_not_called()

			mock.revert(api_mock)
		end)
	end)
end)
