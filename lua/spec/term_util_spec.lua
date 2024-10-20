local mock = require("luassert.mock")
local stub = require("luassert.stub")
local assert = require("luassert")

local default_config = {
	type_opts = {
		horizontal = { location = "rightbelow", split_ratio = 0.3, list_width = 15 },
		vertical = { location = "rightbelow", split_ratio = 0.5, list_width = 15 },
		floating = {
			relative = "editor",
			row = 0.3,
			col = 0.25,
			width = 0.5,
			height = 0.4,
			border = "single",
			list_width = 15,
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
	local term_list = require("simpleterm.term_list")
	local type = "horizontal"
	local api_mock

	after_each(function()
		term_util._terms = {}

		mock.revert(vim.api)
		mock.revert(vim.fn)
		mock.revert(term_list)
	end)

	describe("create_and_show_term", function()
		it("creates and shows a new terminal", function()
			api_mock = mock(vim.api, true)
			mock(vim.fn, true)
			mock(term_list, true)

			local buf = 1
			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }
			local term = { id = 1, buf = buf, open = true, type = type, shell = default_config.shell }

			api_mock.nvim_create_buf.returns(buf)

			term_util.create_and_show_term(type, win, default_config)

			assert.are.same({ [type] = { [1] = term } }, term_util._terms)
			assert.stub(vim.api.nvim_buf_is_valid).was_not_called()
			assert.stub(vim.api.nvim_create_buf).was_called_with(false, true)
			assert.stub(vim.api.nvim_win_set_buf).was_called_with(win.term_win, buf)
			assert.stub(term_list.render_term_names).was_called_with(win.list_win, { [1] = term })
		end)

		it("creates multiple new terminals", function()
			api_mock = mock(vim.api, true)
			mock(vim.fn, true)
			mock(term_list, true)

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }
			local buf1 = 1
			local buf2 = 2
			local term1 = { id = 1, buf = buf1, open = true, type = type, shell = default_config.shell }
			local term1_closed = { id = 1, buf = buf1, open = false, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = buf2, open = true, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.returns(true)
			api_mock.nvim_create_buf.returns(buf1)

			term_util.create_and_show_term(type, win, default_config)
			assert.are.same({ [type] = { [1] = term1 } }, term_util._terms)

			api_mock.nvim_create_buf.returns(buf2)
			term_util.create_and_show_term(type, win, default_config)
			assert.are.same({ [type] = { [1] = term1_closed, [2] = term2 } }, term_util._terms)

			assert.stub(api_mock.nvim_buf_is_valid).was_called_with(buf1)
			assert.stub(api_mock.nvim_create_buf).was_called(2)
			assert.stub(api_mock.nvim_create_buf).was_called_with(false, true)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, buf1)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, buf2)
			assert.stub(term_list.render_term_names).was_called_with(win.list_win, { [1] = term1 })
			assert.stub(term_list.render_term_names).was_called_with(win.list_win, { [1] = term1_closed, [2] = term2 })
			assert.stub(vim.fn.termopen).was_called_with(default_config.shell)
		end)

		it("creates multiple new terminals when remaining terminal is invalid", function()
			api_mock = mock(vim.api, true)
			mock(vim.fn, true)
			mock(term_list, true)

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }
			local buf1 = 1
			local buf2 = 2
			local term1 = { id = 1, buf = buf1, open = true, type = type, shell = default_config.shell }
			local term2 = { id = 1, buf = buf2, open = true, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.returns(false)
			api_mock.nvim_create_buf.returns(buf1)

			term_util.create_and_show_term(type, win, default_config)
			assert.are.same({ [type] = { [1] = term1 } }, term_util._terms)

			api_mock.nvim_create_buf.returns(buf2)
			term_util.create_and_show_term(type, win, default_config)
			assert.are.same({ [type] = { [1] = term2 } }, term_util._terms)

			assert.stub(api_mock.nvim_buf_is_valid).was_called_with(buf1)
			assert.stub(api_mock.nvim_create_buf).was_called(2)
			assert.stub(api_mock.nvim_create_buf).was_called_with(false, true)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, buf1)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, buf2)
			assert.stub(term_list.render_term_names).was_called_with(win.list_win, { [1] = term1 })
			assert.stub(term_list.render_term_names).was_called_with(win.list_win, { [1] = term2 })
			assert.stub(vim.fn.termopen).was_called_with(default_config.shell)
		end)
	end)

	describe("toggle_term_in_win", function()
		it("creates new terminal if there is no existing terminal", function()
			mock(term_util, "create_and_show_term")

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }

			term_util.toggle_term_in_win(type, win, default_config)

			assert.stub(term_util.toggle_term_in_win).was_called_with(type, win, default_config)

			mock.revert(term_util)
		end)

		it("shows the already open terminal if exists", function()
			api_mock = mock(vim.api, true)
			mock(vim.fn, true)
			mock(term_list, true)

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }
			local open_term_buf = 3
			local term1 = { id = 1, buf = 1, open = false, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = 2, open = false, type = type, shell = default_config.shell }
			local term3 = { id = 3, buf = open_term_buf, open = true, type = type, shell = default_config.shell }
			local term4 = { id = 4, buf = 4, open = false, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.returns(true)

			term_util._terms = { [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }

			term_util.toggle_term_in_win(type, win, default_config)

			assert.stub(api_mock.nvim_buf_is_valid).was_called(4)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, open_term_buf)
			assert
				.stub(term_list.render_term_names)
				.was_called_with(win.list_win, { [1] = term1, [2] = term2, [3] = term3, [4] = term4 })
			assert.are.same({ [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }, term_util._terms)
		end)

		it("shows last valid terminal if there is any", function()
			api_mock = mock(vim.api, true)
			mock(vim.fn, true)
			mock(term_list, true)

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }
			local last_term_buffer = 4
			local term1 = { id = 1, buf = 1, open = false, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = 2, open = false, type = type, shell = default_config.shell }
			local term3 = { id = 3, buf = 3, open = false, type = type, shell = default_config.shell }
			local term3_as_second = { id = 2, buf = 3, open = false, type = type, shell = default_config.shell }
			local term4 = { id = 4, buf = last_term_buffer, open = false, type = type, shell = default_config.shell }
			local term4_open =
				{ id = 3, buf = last_term_buffer, open = true, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.on_call_with(1).returns(true)
			api_mock.nvim_buf_is_valid.on_call_with(2).returns(false)
			api_mock.nvim_buf_is_valid.on_call_with(3).returns(true)
			api_mock.nvim_buf_is_valid.on_call_with(4).returns(true)

			term_util._terms = { [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }

			term_util.toggle_term_in_win(type, win, default_config)

			assert.stub(api_mock.nvim_buf_is_valid).was_called(4)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, last_term_buffer)
			assert
				.stub(term_list.render_term_names)
				.was_called_with(win.list_win, { [1] = term1, [2] = term3_as_second, [3] = term4_open })
			assert.are.same({ [type] = { [1] = term1, [2] = term3_as_second, [3] = term4_open } }, term_util._terms)
		end)

		it("creates new terminal if existing terminals were all invalid", function()
			api_mock = mock(vim.api, true)
			stub(term_util, "create_and_show_term")

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }
			local term1 = { id = 1, buf = 1, open = false, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = 2, open = false, type = type, shell = default_config.shell }
			local term3 = { id = 3, buf = 3, open = false, type = type, shell = default_config.shell }
			local term4 = { id = 4, buf = 4, open = false, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.returns(false)

			term_util._terms = { [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }

			term_util.toggle_term_in_win(type, win, default_config)

			assert.stub(api_mock.nvim_buf_is_valid).was_called(4)
			assert.are.same({ [type] = {} }, term_util._terms)
			assert.stub(term_util.create_and_show_term).was_called_with(type, win, default_config)

			mock.revert(term_util)
		end)
	end)

	describe("switch_to_next_term", function()
		it("switches to the terminal right after the current terminal", function()
			api_mock = mock(vim.api, true)
			mock(term_list, true)

			local term_win = 1
			local list_win = 2
			local next_term_buf = 4
			local win = { term_win = term_win, list_win = list_win }
			local term1 = { id = 1, buf = 1, open = false, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = 2, open = false, type = type, shell = default_config.shell }
			local term3 = { id = 3, buf = 3, open = true, type = type, shell = default_config.shell }
			local term3_closed = { id = 3, buf = 3, open = false, type = type, shell = default_config.shell }
			local term4 = { id = 4, buf = next_term_buf, open = false, type = type, shell = default_config.shell }
			local term4_open = { id = 4, buf = next_term_buf, open = true, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.returns(true)

			term_util._terms = { [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }

			term_util.switch_to_next_term(type, win)

			assert.stub(api_mock.nvim_buf_is_valid).was_called(4)
			assert.are.same(
				{ [type] = { [1] = term1, [2] = term2, [3] = term3_closed, [4] = term4_open } },
				term_util._terms
			)
			assert
				.stub(term_list.render_term_names)
				.was_called_with(win.list_win, { [1] = term1, [2] = term2, [3] = term3_closed, [4] = term4_open })
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, next_term_buf)
		end)

		it("switches to the first terminal after the last", function()
			api_mock = mock(vim.api, true)
			mock(term_list, true)

			local term_win = 1
			local list_win = 2
			local next_term_buf = 1
			local win = { term_win = term_win, list_win = list_win }
			local term1 = { id = 1, buf = next_term_buf, open = false, type = type, shell = default_config.shell }
			local term1_open = { id = 1, buf = next_term_buf, open = true, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = 2, open = false, type = type, shell = default_config.shell }
			local term3 = { id = 3, buf = 3, open = false, type = type, shell = default_config.shell }
			local term4 = { id = 4, buf = 4, open = true, type = type, shell = default_config.shell }
			local term4_closed = { id = 4, buf = 4, open = false, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.returns(true)

			term_util._terms = { [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }

			term_util.switch_to_next_term(type, win)

			assert.stub(api_mock.nvim_buf_is_valid).was_called(4)
			assert.are.same(
				{ [type] = { [1] = term1_open, [2] = term2, [3] = term3, [4] = term4_closed } },
				term_util._terms
			)
			assert
				.stub(term_list.render_term_names)
				.was_called_with(win.list_win, { [1] = term1_open, [2] = term2, [3] = term3, [4] = term4_closed })
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, next_term_buf)
		end)

		it("switches to the first valid terminal after the last", function()
			api_mock = mock(vim.api, true)
			mock(term_list, true)

			local term_win = 1
			local list_win = 2
			local next_term_buf = 2
			local win = { term_win = term_win, list_win = list_win }
			local term1 = { id = 1, buf = 1, open = false, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = next_term_buf, open = false, type = type, shell = default_config.shell }
			local term2_open = { id = 1, buf = next_term_buf, open = true, type = type, shell = default_config.shell }
			local term3 = { id = 3, buf = 3, open = false, type = type, shell = default_config.shell }
			local term3_as_second = { id = 2, buf = 3, open = false, type = type, shell = default_config.shell }
			local term4 = { id = 4, buf = 4, open = true, type = type, shell = default_config.shell }
			local term4_closed = { id = 3, buf = 4, open = false, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.on_call_with(1).returns(false)
			api_mock.nvim_buf_is_valid.on_call_with(2).returns(true)
			api_mock.nvim_buf_is_valid.on_call_with(3).returns(true)
			api_mock.nvim_buf_is_valid.on_call_with(4).returns(true)

			term_util._terms = { [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }

			term_util.switch_to_next_term(type, win)

			assert.stub(api_mock.nvim_buf_is_valid).was_called(4)
			assert.are.same(
				{ [type] = { [1] = term2_open, [2] = term3_as_second, [3] = term4_closed } },
				term_util._terms
			)
			assert
				.stub(term_list.render_term_names)
				.was_called_with(win.list_win, { [1] = term2_open, [2] = term3_as_second, [3] = term4_closed })
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, next_term_buf)
		end)

		it("does not do anything if there is no terminal", function()
			api_mock = mock(vim.api, true)

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }

			api_mock.nvim_buf_is_valid.returns(true)

			term_util.switch_to_next_term(type, win)

			assert.stub(api_mock.nvim_buf_is_valid).was_not_called()
			assert.are.same({}, term_util._terms)
			assert.stub(api_mock.nvim_win_set_buf).was_not_called()
		end)

		it("does not do anything if there is no previously open terminal", function()
			api_mock = mock(vim.api, true)

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }
			local term1 = { id = 1, buf = 1, open = false, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = 2, open = false, type = type, shell = default_config.shell }
			local term3 = { id = 3, buf = 3, open = false, type = type, shell = default_config.shell }
			local term4 = { id = 4, buf = 4, open = false, type = type, shell = default_config.shell }

			api_mock.nvim_buf_is_valid.returns(true)

			term_util._terms = { [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }

			term_util.switch_to_next_term(type, win)

			assert.stub(api_mock.nvim_buf_is_valid).was_called(4)
			assert.are.same({ [type] = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 } }, term_util._terms)
			assert.stub(api_mock.nvim_win_set_buf).was_not_called()
		end)
	end)
end)
